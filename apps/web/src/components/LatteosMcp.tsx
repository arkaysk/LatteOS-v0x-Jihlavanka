// LatteOS (ADR 0202): the MCP servers installed in LensAI on this computer, as a second way into Connectors. Shown only
// where the server has `LATTEOS_MCP_URL` set; a server added here is an ordinary custom connection.
import { useConnectLatteosMcp, useLatteosMcp } from "@agenteschat/client";
import { errorText } from "@agenteschat/client/lib/errors";
import { can } from "@agenteschat/client/lib/permissions";
import { Button, Card, CardHeader, Dialog, EmptyState, Icon, SearchField, Segmented } from "@agenteschat/ui";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useOrg } from "@/components/org-context";
import { useToast } from "@/lib/toast";

type Cat = "all" | "connected" | "groups" | "servers";

export function LatteosMcpCard() {
  const { t } = useTranslation();
  const { org } = useOrg();
  const toast = useToast();
  const mcp = useLatteosMcp(org.id);
  const connect = useConnectLatteosMcp(org.id);
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const [cat, setCat] = useState<Cat>("all");
  if (!mcp.data?.enabled) return null;
  const { available, connected } = mcp.data;
  const have = new Set(connected.map((c) => c.label));
  const needle = q.trim().toLowerCase();
  // the gateway's ids: "one.<name>" a server alone, else a ToolHive group (a dot is never in a group's name)
  const solo = (s: { id: string }) => s.id.startsWith("one.");
  const inCat = (s: { id: string; name: string }, c: Cat) =>
    c === "all" || (c === "connected" ? have.has(s.name) : c === "servers" ? solo(s) : !solo(s));
  const shown = available.filter(
    (s) => inCat(s, cat) && (!needle || `${s.name} ${s.what}`.toLowerCase().includes(needle)),
  );
  const cats: Cat[] = ["all", "connected", "groups", "servers"];
  const catLabel = (c: Cat) =>
    c === "all"
      ? t("connectors.category.all")
      : c === "connected"
        ? t("connectors.connectedFilter")
        : t(`latteosMcp.${c}`);
  const count = (c: Cat) => available.filter((s) => inCat(s, c)).length;
  const mayAdd = can(org, "manage_connectors");
  return (
    <Card aria-labelledby="sec-latteos-mcp">
      <CardHeader
        id="sec-latteos-mcp"
        icon="plug"
        title={t("latteosMcp.title")}
        action={
          mayAdd && (
            <Button size="sm" icon="plus" aria-haspopup="dialog" onClick={() => setOpen(true)}>
              {t("latteosMcp.add")}
            </Button>
          )
        }
      />
      {/* what is connected from here is listed (with its agents and Disconnect) in the MCP card under this one */}
      <p className="small muted">{connected.length === 0 ? t("latteosMcp.none") : t("latteosMcp.where")}</p>
      <Dialog
        open={open}
        onOpenChange={(next) => {
          setOpen(next);
          if (!next) {
            setQ("");
            setCat("all");
          }
        }}
        title={t("latteosMcp.add")}
        closeLabel={t("common.close")}
        width={960}
        className="catalog"
      >
        <div className="catalog__tools">
          <SearchField
            size="sm"
            className="catalog__search"
            aria-label={t("latteosMcp.search")}
            placeholder={t("latteosMcp.search")}
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onClear={() => setQ("")}
            clearLabel={t("filters.clearSearch")}
          />
          {/* Phones: the kinds as one row (no room for the list beside the grid), as in the Connectors catalog. */}
          <Segmented
            size="sm"
            className="catalog__filters"
            label={t("connectors.categories")}
            value={cat}
            onValueChange={(v) => setCat(v as Cat)}
            options={cats.map((c) => ({ value: c, label: catLabel(c), count: count(c) }))}
          />
        </div>
        <div className="catalog__body">
          <nav className="catalog__cats" aria-label={t("connectors.categories")}>
            {cats.map((c) => (
              <button
                key={c}
                type="button"
                className="catalog__cat"
                data-rule={c === "connected" || undefined}
                aria-pressed={cat === c}
                onClick={() => setCat(c)}
              >
                <span className="catalog__cat-name">{catLabel(c)}</span>
                <span className="catalog__cat-count">{count(c)}</span>
              </button>
            ))}
          </nav>
          {/* biome-ignore lint/a11y/useSemanticElements: a scroll region, not a fieldset */}
          <div className="catalog__list" role="region" aria-label={t("latteosMcp.title")}>
            {shown.length === 0 ? (
              <EmptyState
                className="catalog__empty"
                title={available.length === 0 ? t("latteosMcp.noneInstalled") : t("connectors.empty", { q: q.trim() })}
              >
                {available.length === 0 ? t("latteosMcp.noneInstalledText") : null}
              </EmptyState>
            ) : (
              <ul className="catalog-grid">
                {shown.map((s) => {
                  const done = have.has(s.name);
                  return (
                    <li key={s.id}>
                      <button
                        type="button"
                        className="catalog-tile"
                        disabled={done || connect.isPending}
                        aria-label={done ? t("connectors.tileConnected", { name: s.name }) : s.name}
                        title={s.name}
                        onClick={() =>
                          connect.mutate(s.id, {
                            onSuccess: () => {
                              toast.show(t("latteosMcp.added", { name: s.name }));
                              setOpen(false);
                            },
                            onError: (e) => toast.show(errorText(t, e), "error"),
                          })
                        }
                      >
                        <span className="catalog-tile__head">
                          <span className="catalog-icon">
                            <span className="connector-icon connector-icon--mono" aria-hidden="true">
                              <Icon name={solo(s) ? "plug" : "layers"} />
                            </span>
                            {done && (
                              <span className="catalog-icon__check" aria-hidden="true">
                                <Icon name="check" size={14} />
                              </span>
                            )}
                          </span>
                          <span className="catalog-tile__name">{s.name}</span>
                        </span>
                        <span className="catalog-tile__desc">
                          {solo(s) ? t("latteosMcp.inGroup", { group: s.what }) : s.what}
                        </span>
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </div>
      </Dialog>
    </Card>
  );
}
