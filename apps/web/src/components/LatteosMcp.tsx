// LatteOS (ADR 0202): the MCP servers installed in LensAI on this computer, as a second way into Connectors. Shown only
// where the server has `LATTEOS_MCP_URL` set; a server added here is an ordinary custom connection.
import { useConnectLatteosMcp, useLatteosMcp } from "@agenteschat/client";
import { errorText } from "@agenteschat/client/lib/errors";
import { can } from "@agenteschat/client/lib/permissions";
import { Button, Card, CardHeader, Dialog, EmptyState, Icon, List, SearchField } from "@agenteschat/ui";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useOrg } from "@/components/org-context";
import { useToast } from "@/lib/toast";

export function LatteosMcpCard() {
  const { t } = useTranslation();
  const { org } = useOrg();
  const toast = useToast();
  const mcp = useLatteosMcp(org.id);
  const connect = useConnectLatteosMcp(org.id);
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  if (!mcp.data?.enabled) return null;
  const { available, connected } = mcp.data;
  const have = new Set(connected.map((c) => c.label));
  const needle = q.trim().toLowerCase();
  const shown = available.filter((s) => !needle || `${s.name} ${s.what}`.toLowerCase().includes(needle));
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
      {connected.length === 0 ? (
        <p className="small muted">{t("latteosMcp.none")}</p>
      ) : (
        <List className="connected-list" aria-label={t("latteosMcp.list")}>
          {connected.map((c) => (
            <li key={c.id} className="small ac-iconline">
              <Icon name="check" size={14} />
              <span>{c.label}</span>
            </li>
          ))}
        </List>
      )}
      <Dialog
        open={open}
        onOpenChange={(next) => {
          setOpen(next);
          if (!next) setQ("");
        }}
        title={t("latteosMcp.add")}
        closeLabel={t("common.close")}
        width={720}
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
        </div>
        <div className="catalog__body">
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
                          <span className="connector-icon connector-icon--mono" aria-hidden="true">
                            <Icon name="plug" />
                          </span>
                          <span className="catalog-tile__name">{s.name}</span>
                        </span>
                        <span className="catalog-tile__desc">{done ? t("latteosMcp.connected") : s.what}</span>
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
