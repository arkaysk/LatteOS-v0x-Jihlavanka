// LatteOS (ROADMAP 10B.79, the user's 19. 11.: "as on GitHub"): an online project's Conflicts and History on its
// page. A conflict is a computer's changes git couldn't merge with the server's: its files are resolved one by one
// (take the server's, keep the computer's, keep both, edit by hand, merge with an AI) and saved together, as the
// server's resolution needs every conflicting file.
import {
  type ProjectConflict,
  useAiMerge,
  useConflictSides,
  useProjectConflicts,
  useProjectHistory,
  useResolveConflict,
} from "@agenteschat/client";
import { errorText } from "@agenteschat/client/lib/errors";
import { relativeTime } from "@agenteschat/client/lib/format";
import { Button, Dialog, DialogBody, DialogFooter, Diff, diffLines, Icon, Textarea } from "@agenteschat/ui";
import { useState } from "react";
import { useTranslation } from "react-i18next";
import { useOrg } from "@/components/org-context";
import { useToast } from "@/lib/toast";

/** The computer's copy kept beside the server's: "kapitola.md" → "kapitola (latte-lab).md". */
const copyPath = (path: string, computer: string) => {
  const dot = path.lastIndexOf(".");
  const slash = path.lastIndexOf("/");
  return dot > slash + 1 ? `${path.slice(0, dot)} (${computer})${path.slice(dot)}` : `${path} (${computer})`;
};

/** The conflicts waiting, one row per computer with its files; a file opens its resolution. */
export function ProjectConflicts({ categoryId }: { categoryId: string }) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const conflicts = (useProjectConflicts(org.id, categoryId).data?.conflicts ?? []).filter((c) => c.files.length > 0);
  const [open, setOpen] = useState<{ conflict: ProjectConflict; start: number } | null>(null);
  if (!conflicts.length) return null;
  return (
    <section className="project-page__part project-page__conflicts">
      <h2 className="project-page__part-head">
        <Icon name="alert" size={16} /> {t("projectPage.conflicts")}
        <span className="project-page__count">{conflicts.length}</span>
      </h2>
      <p className="project-page__hint">{t("projectPage.conflictsHint")}</p>
      <ul className="project-page__files">
        {conflicts.map((c) =>
          c.files.map((f, i) => (
            <li key={`${c.computer}/${f}`}>
              <button
                type="button"
                className="project-page__file project-page__file--button"
                onClick={() => setOpen({ conflict: c, start: i })}
              >
                <Icon name="document" size={16} />
                <span className="project-page__chat-name">{f}</span>
                <span className="project-page__when">{t("projectPage.conflictFrom", { computer: c.computer })}</span>
              </button>
            </li>
          )),
        )}
      </ul>
      {open && (
        <ConflictDialog
          categoryId={categoryId}
          conflict={open.conflict}
          start={open.start}
          onClose={() => setOpen(null)}
        />
      )}
    </section>
  );
}

function ConflictDialog({
  categoryId,
  conflict,
  start,
  onClose,
}: {
  categoryId: string;
  conflict: ProjectConflict;
  start: number;
  onClose: () => void;
}) {
  const { t } = useTranslation();
  const { org } = useOrg();
  const toast = useToast();
  const { computer, files } = conflict;
  const [index, setIndex] = useState(start);
  // each file's final texts by path (a "keep both" gives two); null: removed
  const [chosen, setChosen] = useState<Record<string, Record<string, string | null>>>({});
  const [draft, setDraft] = useState<string | null>(null);
  const file = files[index] ?? "";
  const sides = useConflictSides(org.id, categoryId, computer, file || null).data;
  const merge = useAiMerge(org.id, categoryId);
  const resolve = useResolveConflict(org.id, categoryId);
  const done = files.every((f) => chosen[f]);
  const choose = (texts: Record<string, string | null>) => {
    setChosen((c) => ({ ...c, [file]: texts }));
    setDraft(null);
    const next = files.findIndex((f, i) => i !== index && !chosen[f]);
    if (next >= 0) setIndex(next);
  };
  const save = () =>
    resolve.mutate(
      { computer, files: Object.assign({}, ...files.map((f) => chosen[f])) },
      {
        onSuccess: () => {
          toast.show(t("projectPage.resolved"));
          onClose();
        },
        onError: (e) => toast.show(errorText(t, e), "error"),
      },
    );
  const lines = (from: string, to: string) => diffLines(from.split("\n"), to.split("\n"));
  return (
    <Dialog
      open
      onOpenChange={(o) => !o && onClose()}
      title={t("projectPage.conflictTitle", { file })}
      subtitle={t("projectPage.conflictStep", { n: index + 1, count: files.length })}
      closeLabel={t("common.close")}
      width={1100}
    >
      <DialogBody className="project-conflict">
        {!sides ? (
          <p className="project-page__empty">{t("projectPage.loading")}</p>
        ) : draft === null ? (
          <div className="project-conflict__sides">
            <section className="project-conflict__side">
              <h3>{t("projectPage.serverSide")}</h3>
              <Diff
                code
                lines={lines(sides.base, sides.server)}
                addedLabel={t("projectPage.added")}
                removedLabel={t("projectPage.removed")}
                aria-label={t("projectPage.serverSide")}
              />
            </section>
            <section className="project-conflict__side">
              <h3>{t("projectPage.computerSide", { computer })}</h3>
              <Diff
                code
                lines={lines(sides.base, sides.computer)}
                addedLabel={t("projectPage.added")}
                removedLabel={t("projectPage.removed")}
                aria-label={t("projectPage.computerSide", { computer })}
              />
            </section>
          </div>
        ) : (
          <Textarea
            className="project-conflict__edit"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            rows={20}
            aria-label={t("projectPage.editByHand")}
          />
        )}
        {chosen[file] && <p className="project-page__hint">{t("projectPage.chosen")}</p>}
        {sides && (
          <div className="project-conflict__choices">
            {draft === null ? (
              <>
                <Button size="sm" onClick={() => choose({ [file]: sides.server })}>
                  {t("projectPage.takeServer")}
                </Button>
                <Button size="sm" onClick={() => choose({ [file]: sides.computer })}>
                  {t("projectPage.keepComputer", { computer })}
                </Button>
                <Button
                  size="sm"
                  onClick={() => choose({ [file]: sides.server, [copyPath(file, computer)]: sides.computer })}
                >
                  {t("projectPage.keepBoth")}
                </Button>
                <Button size="sm" icon="edit" onClick={() => setDraft(sides.merged)}>
                  {t("projectPage.editByHand")}
                </Button>
                <Button
                  size="sm"
                  icon="sparkle"
                  loading={merge.isPending}
                  onClick={() =>
                    merge.mutate(
                      { computer, path: file },
                      {
                        onSuccess: (r) => setDraft(r.text),
                        onError: (e) => toast.show(errorText(t, e), "error"),
                      },
                    )
                  }
                >
                  {t("projectPage.mergeWithAi")}
                </Button>
              </>
            ) : (
              <>
                <Button size="sm" onClick={() => setDraft(null)}>
                  {t("common.cancel")}
                </Button>
                <Button size="sm" variant="primary" onClick={() => choose({ [file]: draft })}>
                  {t("projectPage.useText")}
                </Button>
              </>
            )}
          </div>
        )}
      </DialogBody>
      <DialogFooter
        note={
          files.length > 1 ? (
            <span className="project-conflict__nav">
              {files.map((f, i) => (
                <button
                  key={f}
                  type="button"
                  className="ac-link"
                  aria-current={i === index}
                  onClick={() => {
                    setIndex(i);
                    setDraft(null);
                  }}
                >
                  {chosen[f] ? "✓ " : ""}
                  {f}
                </button>
              ))}
            </span>
          ) : undefined
        }
      >
        <Button onClick={onClose}>{t("common.cancel")}</Button>
        <Button variant="primary" disabled={!done} loading={resolve.isPending} onClick={save}>
          {t("projectPage.saveResolution")}
        </Button>
      </DialogFooter>
    </Dialog>
  );
}

const STATUS: Record<string, string> = { A: "add", M: "edit", D: "remove" };

/** What changed, the newest first: who, when, what they said, and its files on demand. */
export function ProjectHistory({ categoryId }: { categoryId: string }) {
  const { t, i18n } = useTranslation();
  const { org } = useOrg();
  const changes = useProjectHistory(org.id, categoryId).data?.changes ?? [];
  const [shown, setShown] = useState(20);
  const [opened, setOpened] = useState<string | null>(null);
  return (
    <section className="project-page__part">
      <h2 className="project-page__part-head">
        <Icon name="clock" size={16} /> {t("projectPage.history")}
      </h2>
      {changes.length === 0 ? (
        <p className="project-page__empty">{t("projectPage.noHistory")}</p>
      ) : (
        <ul className="project-page__chats">
          {changes.slice(0, shown).map((c) => (
            <li key={c.id}>
              <button
                type="button"
                className="project-page__chat project-page__file--button"
                aria-expanded={opened === c.id}
                onClick={() => setOpened(opened === c.id ? null : c.id)}
              >
                <span className="project-page__chat-name">
                  <strong>{c.author}</strong> {c.message}
                </span>
                <span className="project-page__when">{t("projectPage.fileCount", { count: c.files.length })}</span>
                <span className="project-page__when">{relativeTime(t, i18n.language, c.at)}</span>
              </button>
              {opened === c.id && (
                <ul className="project-page__history-files">
                  {c.files.map((f) => (
                    <li key={f.path} data-status={STATUS[f.status] ?? "edit"}>
                      <span className="project-page__mark">{f.status}</span> {f.path}
                    </li>
                  ))}
                </ul>
              )}
            </li>
          ))}
        </ul>
      )}
      {changes.length > shown && (
        <Button size="sm" variant="ghost" className="project-page__more" onClick={() => setShown(shown + 20)}>
          {t("projectPage.showMore")}
        </Button>
      )}
    </section>
  );
}
