import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { projectsDir } from "./channel-categories";
import { ValidationError } from "./errors";

/**
 * LatteOS (ROADMAP 10B.79, the user's 19. 11.: "as on GitHub"): an online project's history is a git repository on
 * the server, hidden in the projects' folder (`.repos/ID.git`); no git server of its own. Each computer's runner
 * commits its copy, pulls with git's own merge and pushes. Changes that touch the same lines are a conflict: the
 * runner pushes its side to `refs/conflicts/COMPUTER` and waits; the project's page shows both sides, and the
 * person (or an agent for them) resolves it here — a merge commit the runner then simply takes.
 */
export const MAIN = "main";
const CONFLICT_REFS = "refs/conflicts/";
const SERVER = { name: "agentgram", email: "agentgram@localhost" };

/** The project's repository on the server; made bare when first asked for (a project made online). */
export function projectRepo(categoryId: string): string | null {
  const root = projectsDir();
  if (!root || !/^[0-9a-f-]{36}$/.test(categoryId)) return null;
  const dir = path.join(root, ".repos", `${categoryId}.git`);
  return dir;
}

export async function git(repo: string, args: string[], opts: { input?: string; env?: Record<string, string> } = {}) {
  const proc = Bun.spawn(["git", "-C", repo, ...args], {
    stdin: opts.input === undefined ? "ignore" : new TextEncoder().encode(opts.input),
    stdout: "pipe",
    stderr: "pipe",
    env: {
      ...process.env,
      GIT_AUTHOR_NAME: SERVER.name,
      GIT_AUTHOR_EMAIL: SERVER.email,
      GIT_COMMITTER_NAME: SERVER.name,
      GIT_COMMITTER_EMAIL: SERVER.email,
      ...opts.env,
    },
  });
  const [out, err, code] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  return { out, err, code };
}

/** Its bare repository, made now if it isn't (main as its branch). */
export async function ensureProjectRepo(categoryId: string): Promise<string | null> {
  const repo = projectRepo(categoryId);
  if (!repo) return null;
  mkdirSync(repo, { recursive: true });
  if ((await git(repo, ["rev-parse", "--is-bare-repository"])).out.trim() !== "true") {
    await git(repo, ["init", "--bare", "--initial-branch", MAIN]);
    // a computer's push may be large (a project's pictures and sounds)
    await git(repo, ["config", "http.receivepack", "true"]);
  }
  return repo;
}

const hasMain = async (repo: string) => (await git(repo, ["rev-parse", "--verify", "-q", MAIN])).code === 0;

/** What changed in the project, the newest first: who, when, what they said and which files. */
export async function projectHistory(categoryId: string, most = 50) {
  const repo = projectRepo(categoryId);
  if (!repo || !(await hasMain(repo))) return [];
  const { out } = await git(repo, ["log", MAIN, `-n${most}`, "--name-status", "--format=%x1e%H%x1f%an%x1f%aI%x1f%s"]);
  return out
    .split("\x1e")
    .filter((c) => c.trim())
    .map((c) => {
      const [head = "", ...lines] = c.split("\n");
      const [id = "", author = "", at = "", message = ""] = head.split("\x1f");
      const files = lines
        .filter((l) => l.trim())
        .map((l) => {
          const [status = "", ...rest] = l.split("\t");
          return { status: status.slice(0, 1), path: rest[rest.length - 1] ?? "" };
        });
      return { id, author, at, message, files };
    });
}

/** The conflicts waiting: one per computer that couldn't merge, with the files both sides changed. */
export async function projectConflicts(categoryId: string) {
  const repo = projectRepo(categoryId);
  if (!repo || !(await hasMain(repo))) return [];
  const refs = (await git(repo, ["for-each-ref", "--format=%(refname)", CONFLICT_REFS])).out
    .split("\n")
    .filter(Boolean);
  const out: { computer: string; files: string[] }[] = [];
  for (const ref of refs) {
    const merged = await git(repo, ["merge-tree", "--write-tree", "--name-only", "--no-messages", MAIN, ref]);
    // exit 1: a conflict; the paths follow the tree's id
    const files = merged.code === 1 ? merged.out.split("\n").slice(1).filter(Boolean) : [];
    out.push({ computer: ref.slice(CONFLICT_REFS.length), files: [...new Set(files)] });
  }
  return out;
}

const conflictRef = (computer: string) => {
  if (!/^[\w.-]{1,80}$/.test(computer)) throw new ValidationError("No such conflict");
  return `${CONFLICT_REFS}${computer}`;
};

/** A conflicting file's three sides: what both started from, the server's and the computer's ("" where it isn't). */
export async function conflictSides(categoryId: string, computer: string, file: string) {
  const repo = projectRepo(categoryId);
  if (!repo) throw new ValidationError("This project is not online");
  const ref = conflictRef(computer);
  const base = (await git(repo, ["merge-base", MAIN, ref])).out.trim();
  const show = async (rev: string) => (rev ? (await git(repo, ["show", `${rev}:${file}`])).out : "");
  const [original, theirs, mine] = await Promise.all([show(base), show(MAIN), show(ref)]);
  // git's own merge of the text, with markers where both changed the same lines: where a manual edit starts
  const dir = mkdtempSync(path.join(tmpdir(), "latteos-merge-"));
  try {
    const [m, o, t] = ["mine", "base", "theirs"].map((n) => path.join(dir, n)) as [string, string, string];
    await Promise.all([Bun.write(m, mine), Bun.write(o, original), Bun.write(t, theirs)]);
    const merged = await git(dir, ["merge-file", "-p", "-L", computer, "-L", "base", "-L", "server", m, o, t]);
    return { base: original, server: theirs, computer: mine, merged: merged.out };
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}

/**
 * The person's resolution: each conflicting file's final text (null: removed), the rest as git merged it. A merge
 * commit of the server's side and the computer's, so the computer takes it as it is; the conflict is gone.
 */
export async function resolveConflict(
  categoryId: string,
  computer: string,
  files: Record<string, string | null>,
  by: string,
) {
  const repo = projectRepo(categoryId);
  if (!repo) throw new ValidationError("This project is not online");
  const ref = conflictRef(computer);
  const merged = await git(repo, ["merge-tree", "--write-tree", "--no-messages", MAIN, ref]);
  const tree = merged.out.split("\n")[0]?.trim();
  if (!tree) throw new ValidationError("Nothing to resolve");
  const dir = mkdtempSync(path.join(tmpdir(), "latteos-resolve-"));
  try {
    const env = { GIT_INDEX_FILE: path.join(dir, "index") };
    await git(repo, ["read-tree", tree], { env });
    for (const [file, text] of Object.entries(files)) {
      if (text === null) {
        await git(repo, ["update-index", "--force-remove", "--", file], { env });
        continue;
      }
      const blob = (await git(repo, ["hash-object", "-w", "--stdin"], { input: text })).out.trim();
      await git(repo, ["update-index", "--add", "--cacheinfo", `100644,${blob},${file}`], { env });
    }
    const resolved = (await git(repo, ["write-tree"], { env })).out.trim();
    const commit = (
      await git(
        repo,
        ["commit-tree", resolved, "-p", MAIN, "-p", ref, "-m", `Resolved ${computer}'s conflict (${by})`],
        {
          env: { GIT_AUTHOR_NAME: by },
        },
      )
    ).out.trim();
    if (!commit) throw new ValidationError("The resolution couldn't be saved");
    await git(repo, ["update-ref", `refs/heads/${MAIN}`, commit]);
    await git(repo, ["update-ref", "-d", ref]);
    return commit;
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}
