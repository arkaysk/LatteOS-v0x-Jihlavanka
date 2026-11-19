import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import path from "node:path";

/**
 * LatteOS (ROADMAP 10B.79, the user's 19. 11.: "as on GitHub"): an online project's folder is a git clone of the
 * project's history on the server (project-git.ts); each round this computer commits what changed in it, takes the
 * server's changes with git's own merge and sends its own. When both changed the same lines git can't merge: the
 * merge is undone, this computer's side goes to the server as `refs/conflicts/NAME`, and the project waits here until
 * the person resolves it on the project's page; the next round takes the resolution as it is.
 */
// ponytail: big pictures and sounds go into the history whole; git LFS when a project's history grows too heavy
type Run = (args: string[], cwd: string) => Promise<{ code: number; out: string }>;

export interface ProjectSyncOptions {
  server: string;
  token: string;
  /** This computer's projects' folder. */
  projects: string;
  /** Where a project waiting on its conflict is kept between rounds. */
  stateFile: string;
  /** This computer's name: its commits' author and its conflict's name. */
  name: string;
  fetch?: (url: string, init?: RequestInit) => Promise<Response>;
  git?: Run;
  log?: (line: string) => void;
}

const runGit: Run = async (args, cwd) => {
  const proc = Bun.spawn(["git", ...args], { cwd, stdout: "pipe", stderr: "pipe", stdin: "ignore" });
  const [out, err, code] = await Promise.all([
    new Response(proc.stdout).text(),
    new Response(proc.stderr).text(),
    proc.exited,
  ]);
  return { code, out: out + err };
};

/** What a computer never sends: editors' and systems' leftovers. */
const EXCLUDE = ["*~", ".~lock.*#", "*.swp", ".DS_Store", "Thumbs.db", "*.tmp", "*.part"].join("\n");

/** A computer's name as a git ref's last part. */
export const conflictName = (name: string) => name.replace(/[^\w.-]/g, "-");

/** One round for every online project of the workspace; a project that fails waits for the next round. */
export async function syncOnlineProjects(o: ProjectSyncOptions) {
  const get = o.fetch ?? fetch;
  const git = o.git ?? runGit;
  const base = `${o.server.replace(/\/$/, "")}/api/machines/projects`;
  const listed = await get(base, { headers: { authorization: `Bearer ${o.token}` } });
  if (!listed.ok) return;
  const { projects } = (await listed.json()) as { projects: { id: string; path: string }[] };
  let waiting: Record<string, boolean> = {};
  try {
    waiting = JSON.parse(readFileSync(o.stateFile, "utf8"));
  } catch {
    // the first round
  }
  const conflictRef = `refs/conflicts/${conflictName(o.name)}`;
  for (const project of projects) {
    const folder = path.resolve(o.projects, project.path);
    if (!folder.startsWith(o.projects + path.sep)) continue;
    // the token rides in each call's header, never in the clone's config
    const auth = ["-c", `http.extraHeader=Authorization: Bearer ${o.token}`];
    const me = ["-c", `user.name=${o.name}`, "-c", `user.email=${conflictName(o.name)}@latteos`];
    const run = (args: string[]) => git([...auth, ...me, ...args], folder);
    try {
      mkdirSync(folder, { recursive: true });
      if (!existsSync(path.join(folder, ".git"))) {
        await run(["init", "-q", "--initial-branch", "main"]);
        await run(["remote", "add", "origin", `${base}/${project.id}/git`]);
        writeFileSync(path.join(folder, ".git", "info", "exclude"), `${EXCLUDE}\n`);
      }
      if (waiting[project.id]) {
        // still waiting while its conflict is on the server
        if ((await run(["ls-remote", "origin", conflictRef])).out.trim()) continue;
        delete waiting[project.id];
      }
      await run(["add", "-A"]);
      if ((await run(["diff", "--cached", "--quiet"])).code !== 0)
        await run(["commit", "-q", "-m", `${o.name}: changes`]);
      const fetched = await run(["fetch", "-q", "origin", "main"]);
      const remote = fetched.code === 0 && (await run(["rev-parse", "--verify", "-q", "FETCH_HEAD"])).code === 0;
      const local = (await run(["rev-parse", "--verify", "-q", "HEAD"])).code === 0;
      if (remote && !local) await run(["reset", "-q", "--hard", "FETCH_HEAD"]);
      else if (remote) {
        const merged = await run(["merge", "-q", "--no-edit", "--allow-unrelated-histories", "FETCH_HEAD"]);
        if (merged.code !== 0) {
          await run(["merge", "--abort"]);
          await run(["push", "-q", "--force", "origin", `HEAD:${conflictRef}`]);
          waiting[project.id] = true;
          o.log?.(`project ${project.path}: a conflict, waiting for its resolution`);
          continue;
        }
      }
      if ((await run(["rev-parse", "--verify", "-q", "HEAD"])).code === 0) {
        const pushed = await run(["push", "-q", "origin", "HEAD:main"]);
        if (pushed.code !== 0) o.log?.(`project ${project.path}: ${pushed.out.trim()}`);
      }
    } catch (err) {
      o.log?.(`project ${project.path}: ${err instanceof Error ? err.message : String(err)}`);
    }
  }
  writeFileSync(o.stateFile, JSON.stringify(waiting));
}
