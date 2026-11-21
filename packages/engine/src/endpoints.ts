import { OutboundAddressError } from "@agenteschat/adapters";
import { and, type Database, type Executor, eq, isNull, schema } from "@agenteschat/db";
import {
  customModelId,
  ENDPOINT_STYLES,
  type EndpointStyle,
  listEndpointModels,
  type ModelInfo,
  parseCustomModel,
  setCustomModels,
  type ToolSpec,
} from "@agenteschat/providers";
import { recordAudit } from "./audit";
import { caches } from "./cache";
import { NotFoundError, ValidationError } from "./errors";
import type { ModelGateway } from "./gateway";
import { isLatteosLocal, latteosLocalModels } from "./latteos-local";
import { assertPublicHttpsUrl, publicHttpsFetch, type ResolveHost } from "./net-guard";
import { requirePermission } from "./organizations";
import { isAgentesCloud } from "./telemetry";
import { redactCredentials } from "./tool-detail";

/**
 * A workspace's own model endpoint (ADR 0146): an OpenAI- or Anthropic-compatible server (a gateway, Ollama, vLLM,
 * LM Studio, LiteLLM), kept as a `custom` credential whose options hold its address, API style and the models an
 * admin chose, each with optional prices. Its models are `custom:<credentialId>:<model>`, offered only to its
 * workspace.
 */
export type StoredEndpoint = schema.StoredEndpoint;
export type EndpointModel = StoredEndpoint["models"][number];
export type EndpointCheck = { model: string; check: NonNullable<EndpointModel["check"]>; error?: string };

/** How this server reaches endpoints people type. */
export interface EndpointNet {
  /** Addresses on this server's network and http allowed (`MODEL_ENDPOINTS_PRIVATE`). */
  allowPrivate: boolean;
  /** Outbound HTTP (tests: a fake); absent: plain `fetch` when private addresses are allowed, else the guarded one. */
  fetch?: typeof fetch;
  resolveHost?: ResolveHost;
}

export const MAX_ENDPOINT_MODELS = 100;
const MODEL_ID = /^[\w.:/@+-]{1,200}$/;
/** What a key-less server (a local Ollama) is sent: the SDKs need some key. */
export const ENDPOINT_NO_KEY = "none";

/**
 * Whether this server lets endpoints be private or http: `MODEL_ENDPOINTS_PRIVATE`, else everywhere but the Cloud and
 * a server open to anyone's sign-up (`ALLOW_SIGNUP`), where a stranger's workspace would reach this server's network.
 */
export const allowsPrivateEndpoints = (config: {
  MODEL_ENDPOINTS_PRIVATE?: boolean;
  PUBLIC_URL: string;
  ALLOW_SIGNUP?: boolean;
}) => config.MODEL_ENDPOINTS_PRIVATE ?? (!isAgentesCloud(config.PUBLIC_URL) && !config.ALLOW_SIGNUP);

/** The fetch endpoint calls go through: private addresses allowed or not, every request checked at connect time. */
export const endpointFetch = (net: EndpointNet): typeof fetch =>
  net.fetch ?? (net.allowPrivate ? fetch : publicHttpsFetch());

/**
 * An endpoint's address as its API's SDK takes it: no query, no trailing slash, and the path the SDK adds left out
 * (`/chat/completions`; `/v1` or `/v1/messages` for Anthropic's). Without `allowPrivate`, https only and every
 * address the host resolves to public (`assertPublicHttpsUrl`; each call is checked again when it connects).
 */
export async function endpointAddress(raw: string, style: EndpointStyle, net: EndpointNet): Promise<string> {
  if (!ENDPOINT_STYLES.includes(style)) throw new ValidationError("Pick the API the server speaks", "endpoint.style");
  let url: URL;
  if (net.allowPrivate) {
    try {
      url = new URL(raw.trim());
    } catch {
      throw new ValidationError("Invalid address", "url.invalid");
    }
    if (url.protocol !== "https:" && url.protocol !== "http:")
      throw new ValidationError("Use an https:// or http:// address", "url.invalid");
    if (url.username || url.password)
      throw new ValidationError("The address can't have a user or password", "url.credentials");
  } else url = await assertPublicHttpsUrl(raw.trim(), net.resolveHost);
  const path = url.pathname.replace(/\/+$/, "");
  const base =
    style === "anthropic" ? path.replace(/\/v1(\/messages)?$/, "") : path.replace(/\/chat\/completions$/, "");
  return `${url.origin}${base}`;
}

/** The models an admin chose, checked: ids that look like one, names and prices that make sense, at most 100. */
export function cleanEndpointModels(models: EndpointModel[], previous: EndpointModel[] = []): EndpointModel[] {
  if (models.length === 0) throw new ValidationError("Choose at least one model", "endpoint.no_models");
  if (models.length > MAX_ENDPOINT_MODELS)
    throw new ValidationError(`At most ${MAX_ENDPOINT_MODELS} models`, "endpoint.too_many_models");
  const seen = new Set<string>();
  return models.map((m) => {
    const id = m.id.trim();
    if (!MODEL_ID.test(id)) throw new ValidationError(`"${id}" doesn't look like a model id`, "endpoint.model_id");
    if (seen.has(id)) throw new ValidationError(`${id} is listed twice`, "endpoint.model_id");
    seen.add(id);
    const label = m.label?.trim().slice(0, 120);
    const p = m.prices;
    if (p && Object.values(p).some((v) => !Number.isSafeInteger(v) || v < 0))
      throw new ValidationError("Prices can't be negative", "endpoint.prices");
    const check = previous.find((o) => o.id === id)?.check;
    return { id, ...(label ? { label } : {}), ...(p ? { prices: p } : {}), ...(check ? { check } : {}) };
  });
}

/** An endpoint model as the gateway and the pickers read it: never a pick for routing, the judge or summaries. */
const infoOf = (endpointName: string, m: EndpointModel): ModelInfo => ({
  provider: "custom",
  label: m.label ?? m.id,
  endpoint: endpointName,
  prices: m.prices ?? { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
  ...(m.prices ? {} : { unpriced: true as const }),
  serverSideFallback: false,
  structuredOutput: false,
});

/**
 * Puts an organization's endpoint models in memory (`setCustomModels`) from its live `custom` credentials, read like
 * other credential rows (cached 30 s, dropped by `invalidateDefaults` on any key change).
 */
export async function loadEndpointModels(db: Executor, orgId: string) {
  const rows = (await caches.credentials.getOrLoad(`${orgId}:endpoints`, () =>
    db
      .select({
        id: schema.providerCredentials.id,
        label: schema.providerCredentials.label,
        options: schema.providerCredentials.options,
      })
      .from(schema.providerCredentials)
      .where(
        and(
          eq(schema.providerCredentials.orgId, orgId),
          eq(schema.providerCredentials.provider, "custom"),
          isNull(schema.providerCredentials.revokedAt),
        ),
      ),
  )) as { id: string; label: string; options: { endpoint?: StoredEndpoint } }[];
  // LatteOS: the key of this computer's own models offers every model downloaded here, as LM Studio's list does (none
  // is loaded: the router loads the one an agent asks for), not only those picked when the key was saved
  const live = rows.some((r) => r.options.endpoint && isLatteosLocal(r.options.endpoint.baseURL))
    ? await latteosLocalModels()
    : null;
  const modelsOf = (r: (typeof rows)[number]): EndpointModel[] =>
    live && r.options.endpoint && isLatteosLocal(r.options.endpoint.baseURL)
      ? live.map((m) => ({ id: m.id, label: m.label, check: m.tools ? "ok" : "no_tools" }))
      : (r.options.endpoint?.models ?? []);
  setCustomModels(
    orgId,
    Object.fromEntries(
      rows.flatMap((r) => modelsOf(r).map((m) => [customModelId(r.id, m.id), infoOf(r.label, m)] as const)),
    ),
  );
}

/**
 * What an endpoint lists, before anything is stored (admins): its cleaned address and model ids, or the reason it
 * listed none (the admin then types ids by hand). An address this server won't reach is refused.
 */
export async function listEndpoint(
  db: Database,
  actorId: string,
  orgId: string,
  input: { style: EndpointStyle; baseURL: string; apiKey?: string },
  net: EndpointNet,
): Promise<{ baseURL: string; models: { id: string; label?: string }[]; error?: string }> {
  await requirePermission(db, actorId, orgId, "manage_credentials");
  const baseURL = await endpointAddress(input.baseURL, input.style, net);
  try {
    const models = await listEndpointModels(
      { style: input.style, baseURL },
      input.apiKey?.trim() || ENDPOINT_NO_KEY,
      endpointFetch(net),
    );
    return { baseURL, models };
  } catch (error) {
    if (error instanceof OutboundAddressError)
      throw new ValidationError("This address points to an internal network", "url.internal");
    return { baseURL, models: [], error: redactCredentials(error instanceof Error ? error.message : String(error)) };
  }
}

/** The tool the test call asks for: agents work through tools, so a model that never calls one can't do their work. */
const CHECK_TOOL: ToolSpec = {
  name: "report_status",
  description: "Report that the connection works.",
  inputSchema: { type: "object", properties: { ok: { type: "boolean" } }, required: ["ok"] },
};
const CHECK_TIMEOUT_MS = 60_000;
// ponytail: several local models switched on at once can still outlast the request (Bun's 255 s); the checks are saved anyway
const LOCAL_CHECK_TIMEOUT_MS = 120_000;

/** Whether an endpoint's address is this computer itself (loopback). */
export function onThisComputer(baseURL: string): boolean {
  try {
    const host = new URL(baseURL).hostname.replace(/^\[|\]$/g, "");
    return host === "localhost" || host === "::1" || /^127\./.test(host);
  } catch {
    return false;
  }
}

/**
 * One small call per model of an endpoint (admins), through the Model Gateway (recorded as a `summary` call with its
 * tokens and cost): `ok` when it called the tool it was asked to, `no_tools` when it answered without, `failed` with
 * the server's words. Each model keeps its last result.
 */
export async function checkEndpoint(
  db: Database,
  gateway: Pick<ModelGateway, "complete">,
  actorId: string,
  orgId: string,
  credentialId: string,
): Promise<EndpointCheck[]> {
  await requirePermission(db, actorId, orgId, "manage_credentials");
  const where = and(
    eq(schema.providerCredentials.id, credentialId),
    eq(schema.providerCredentials.orgId, orgId),
    eq(schema.providerCredentials.provider, "custom"),
    isNull(schema.providerCredentials.revokedAt),
  );
  const [row] = await db.select().from(schema.providerCredentials).where(where);
  const endpoint = row?.options.endpoint;
  if (!row || !endpoint) throw new NotFoundError("Credential not found");
  // LatteOS: a server on this computer (llama.cpp's router) loads one model at a time, slowly on a small graphics card:
  // its models are tested one after another and given longer, or each test evicts the one before and they all time out
  const here = onThisComputer(endpoint.baseURL);
  // LatteOS's own models: what each can do is in its file (tools in its chat template), so none is loaded to be tested
  const live = isLatteosLocal(endpoint.baseURL) ? await latteosLocalModels() : null;
  const one = async (m: EndpointModel): Promise<EndpointCheck> => {
    try {
      const r = await gateway.complete({
        orgId,
        kind: "summary",
        model: customModelId(credentialId, m.id),
        system: "You are checking that a connection works.",
        messages: [{ role: "user", content: "Call the report_status tool with ok set to true." }],
        maxTokens: 1024,
        tools: [CHECK_TOOL],
        signal: AbortSignal.timeout(here ? LOCAL_CHECK_TIMEOUT_MS : CHECK_TIMEOUT_MS),
      });
      return { model: m.id, check: r.content.some((b) => b.type === "tool_use") ? "ok" : "no_tools" };
    } catch (error) {
      return { model: m.id, check: "failed", error: error instanceof Error ? error.message : String(error) };
    }
  };
  const results: EndpointCheck[] = [];
  if (live)
    for (const m of endpoint.models) {
      const known = live.find((x) => x.id === m.id);
      results.push(
        known
          ? { model: m.id, check: known.tools ? "ok" : "no_tools" }
          : { model: m.id, check: "failed", error: "Not downloaded on this computer" },
      );
    }
  else if (here) for (const m of endpoint.models) results.push(await one(m));
  else results.push(...(await Promise.all(endpoint.models.map(one))));
  const models = endpoint.models.map((m) => ({ ...m, check: results.find((r) => r.model === m.id)?.check ?? m.check }));
  await db
    .update(schema.providerCredentials)
    .set({ options: { ...row.options, endpoint: { ...endpoint, models } } })
    .where(where);
  caches.credentials.delete(`${orgId}:${credentialId}`);
  caches.credentials.delete(`${orgId}:endpoints`);
  return results;
}

/** Changes which models an endpoint offers and their prices (admins); checks are run again by the caller. */
export async function updateEndpointModels(
  db: Database,
  actorId: string,
  orgId: string,
  credentialId: string,
  models: EndpointModel[],
) {
  await requirePermission(db, actorId, orgId, "manage_credentials");
  const where = and(
    eq(schema.providerCredentials.id, credentialId),
    eq(schema.providerCredentials.orgId, orgId),
    eq(schema.providerCredentials.provider, "custom"),
    isNull(schema.providerCredentials.revokedAt),
  );
  const [row] = await db.select().from(schema.providerCredentials).where(where);
  const endpoint = row?.options.endpoint;
  if (!row || !endpoint) throw new NotFoundError("Credential not found");
  const next = { ...endpoint, models: cleanEndpointModels(models, endpoint.models) };
  await db
    .update(schema.providerCredentials)
    .set({ options: { ...row.options, endpoint: next } })
    .where(where);
  await recordAudit(db, {
    orgId,
    actor: { type: "person", id: actorId },
    action: "credential.models_changed",
    target: { type: "credential", id: credentialId },
    details: { provider: "custom", label: row.label, models: next.models.map((m) => m.id) },
  });
  caches.credentials.delete(`${orgId}:${credentialId}`);
  caches.credentials.delete(`${orgId}:endpoints`);
  return next;
}

/** The organizations of `userId` that have a live endpoint: whose models `GET /models` adds for them. */
export async function endpointOrgsOf(db: Executor, userId: string): Promise<string[]> {
  const rows = await db
    .selectDistinct({ orgId: schema.providerCredentials.orgId })
    .from(schema.providerCredentials)
    .innerJoin(
      schema.organizationMembers,
      and(
        eq(schema.organizationMembers.orgId, schema.providerCredentials.orgId),
        eq(schema.organizationMembers.userId, userId),
      ),
    )
    .where(and(eq(schema.providerCredentials.provider, "custom"), isNull(schema.providerCredentials.revokedAt)));
  return rows.map((r) => r.orgId);
}

/** Prices as people type them (US dollars per million tokens) in nano-USD per token; a cache price absent is the input's. */
export function endpointPricesFromUsd(p: { input: number; output: number; cacheRead?: number; cacheWrite?: number }) {
  const nano = (usd: number) => Math.round(usd * 1000);
  return {
    input: nano(p.input),
    output: nano(p.output),
    cacheRead: nano(p.cacheRead ?? p.input),
    cacheWrite: nano(p.cacheWrite ?? p.input),
  };
}

/** Nano-USD per token back in US dollars per million tokens. */
export const endpointPricesToUsd = (p: NonNullable<EndpointModel["prices"]>) => ({
  input: p.input / 1000,
  output: p.output / 1000,
  cacheRead: p.cacheRead / 1000,
  cacheWrite: p.cacheWrite / 1000,
});

/** What the pickers add for an endpoint's model (ADR 0146): whose credential, its name, and whether it has prices. */
export function pickerEndpoint(id: string, info: ModelInfo) {
  const credentialId = parseCustomModel(id)?.credentialId;
  if (!credentialId) return {};
  return {
    endpoint: { credentialId, name: info.endpoint ?? "" },
    ...(info.unpriced ? { unpriced: true } : {}),
  };
}
