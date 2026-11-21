import { readFileSync } from "node:fs";

/**
 * LatteOS's own models on this computer (ADR 0202): kept apart from latteos.ts, which pulls in the connectors, so the
 * endpoints can read it without an import cycle. setLatteosConfig fills it.
 */
let config: { mcpUrl?: string; mcpTokenFile?: string; localLlmUrl?: string } = {};

export function setLatteosLocal(next: typeof config) {
  config = next;
}

interface LocalDeps {
  fetch?: typeof fetch;
  /** The gateway's master token (read from its file when absent). */
  token?: () => string;
}

/** One of this computer's own models, as LatteOS lists them (`latte-ai local catalog`, through the gateway). */
export interface LatteosLocalModel {
  /** The name the router knows it by (its file's name without .gguf). */
  id: string;
  /** What LM Studio's list shows of it: name · quantization · size. */
  label: string;
  tools: boolean;
  vision: boolean;
  reasoning: boolean;
}

let localModels: { at: number; models: LatteosLocalModel[] } | null = null;

async function gatewayJson(path: string, deps: LocalDeps): Promise<unknown> {
  if (!config.mcpUrl || !config.mcpTokenFile) return null;
  const master = deps.token ? deps.token() : readFileSync(config.mcpTokenFile as string, "utf8").trim();
  try {
    const res = await (deps.fetch ?? fetch)(new URL(path, config.mcpUrl), {
      headers: { authorization: `Bearer ${master}` },
      signal: AbortSignal.timeout(5000),
    });
    return res.ok ? await res.json() : null;
  } catch {
    return null;
  }
}

/** Whether an endpoint's address is LatteOS's own models on this computer (`LATTEOS_LOCAL_LLM_URL`). */
export function isLatteosLocal(baseURL: string): boolean {
  if (!config.localLlmUrl) return false;
  try {
    return new URL(baseURL).origin === new URL(config.localLlmUrl).origin;
  } catch {
    return false;
  }
}

/**
 * Every model downloaded on this computer (none of them loaded: the router loads the one asked for), kept 30 s; null
 * when LatteOS can't be asked. A model downloaded later shows on its own.
 */
export async function latteosLocalModels(deps: LocalDeps = {}): Promise<LatteosLocalModel[] | null> {
  if (localModels && Date.now() - localModels.at < 30_000) return localModels.models;
  const answer = await gatewayJson("/local/models", deps);
  if (!Array.isArray(answer)) return null;
  const models = (answer as Record<string, unknown>[])
    .filter((m) => m && typeof m.id === "string" && /^[\w.+-]{1,200}$/.test(m.id))
    .map((m) => ({
      id: m.id as string,
      label: (typeof m.label === "string" ? m.label : (m.id as string)).slice(0, 120),
      tools: m.tools === true,
      vision: m.vision === true,
      reasoning: m.reasoning === true,
    }));
  localModels = { at: Date.now(), models };
  return models;
}

/** How far the router is with loading a model: `loading` with LatteOS's estimate in percent, or its state. */
export async function latteosLocalProgress(
  model: string,
  deps: LocalDeps = {},
): Promise<{ state: string; percent: number }> {
  if (!config.localLlmUrl || !/^[\w.+-]{1,200}$/.test(model)) return { state: "none", percent: 0 };
  const answer = (await gatewayJson(`/local/progress?model=${encodeURIComponent(model)}`, deps)) as {
    state?: unknown;
    percent?: unknown;
  } | null;
  const state = typeof answer?.state === "string" ? answer.state : "none";
  const percent = typeof answer?.percent === "number" ? Math.max(0, Math.min(100, Math.round(answer.percent))) : 0;
  return { state, percent };
}
