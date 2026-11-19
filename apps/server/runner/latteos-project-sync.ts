import { createHash } from "node:crypto";
import { mkdirSync, readdirSync, readFileSync, renameSync, rmSync, writeFileSync } from "node:fs";
import path from "node:path";

/**
 * LatteOS (ROADMAP 10B.79, the user's 19. 11.): an online project's folder lives on the server, and every computer of
 * the workspace keeps its own copy in step, under its projects' folder (LATTEOS_PROJECTS_DIR), in the same place.
 * Each round compares this computer's files, the server's and what both had at the last round (`project-sync.json`):
 * a file changed on one side goes to the other, one removed on one side goes from the other, and one changed on both
 * keeps both (this computer's as "name (conflict NAME).ext", the server's in its place).
 */
type Sums = Record<string, string>;
type Fetch = (url: string, init?: RequestInit) => Promise<Response>;

export interface ProjectSyncOptions {
  server: string;
  token: string;
  /** This computer's projects' folder. */
  projects: string;
  /** Where what both sides had is kept between rounds. */
  stateFile: string;
  /** This computer's name, in a conflict's copy. */
  name: string;
  fetch?: Fetch;
  log?: (line: string) => void;
}

const sha = (file: string) => createHash("sha256").update(readFileSync(file)).digest("hex");

/** This computer's files of a project's folder (hidden ones left out), each with its sha-256. */
export function localSums(folder: string): Sums {
  const out: Sums = {};
  const walk = (dir: string) => {
    let entries: import("node:fs").Dirent[];
    try {
      entries = readdirSync(dir, { withFileTypes: true });
    } catch {
      return;
    }
    for (const e of entries) {
      if (e.name.startsWith(".")) continue;
      const full = path.join(dir, e.name);
      if (e.isDirectory()) walk(full);
      else if (e.isFile()) out[path.relative(folder, full)] = sha(full);
    }
  };
  walk(folder);
  return out;
}

export type SyncStep =
  | { do: "upload"; path: string }
  | { do: "download"; path: string }
  | { do: "delete-remote"; path: string }
  | { do: "delete-local"; path: string }
  | { do: "conflict"; path: string };

/** What a round does for one project, from both sides' files and what both had last time. */
export function plan(local: Sums, remote: Sums, base: Sums): SyncStep[] {
  const steps: SyncStep[] = [];
  for (const p of new Set([...Object.keys(local), ...Object.keys(remote), ...Object.keys(base)])) {
    const l = local[p];
    const r = remote[p];
    const b = base[p];
    if (l === r) continue;
    const localChanged = l !== b;
    const remoteChanged = r !== b;
    if (localChanged && !remoteChanged) steps.push(l ? { do: "upload", path: p } : { do: "delete-remote", path: p });
    else if (remoteChanged && !localChanged)
      steps.push(r ? { do: "download", path: p } : { do: "delete-local", path: p });
    // changed on both sides: a side that removed it takes the other's; else both are kept
    else if (!l) steps.push({ do: "download", path: p });
    else if (!r) steps.push({ do: "upload", path: p });
    else steps.push({ do: "conflict", path: p });
  }
  return steps;
}

const conflictName = (p: string, name: string) => {
  const ext = path.extname(p);
  return `${p.slice(0, p.length - ext.length)} (conflict ${name})${ext}`;
};

/** One round for every online project of the workspace; a project that fails waits for the next round. */
export async function syncOnlineProjects(o: ProjectSyncOptions) {
  const get = o.fetch ?? fetch;
  const auth = { authorization: `Bearer ${o.token}` };
  const api = `${o.server.replace(/\/$/, "")}/api/machines/projects`;
  const listed = await get(api, { headers: auth });
  if (!listed.ok) return;
  const { projects } = (await listed.json()) as { projects: { id: string; path: string }[] };
  let state: Record<string, Sums> = {};
  try {
    state = JSON.parse(readFileSync(o.stateFile, "utf8"));
  } catch {
    // the first round
  }
  for (const project of projects) {
    const folder = path.resolve(o.projects, project.path);
    if (!folder.startsWith(o.projects + path.sep)) continue;
    try {
      mkdirSync(folder, { recursive: true });
      const res = await get(`${api}/${project.id}/files`, { headers: auth });
      if (!res.ok) continue;
      const remote: Sums = {};
      for (const f of ((await res.json()) as { files: { path: string; sha256: string }[] }).files)
        remote[f.path] = f.sha256;
      const local = localSums(folder);
      const file = (p: string) => `${api}/${project.id}/file?path=${encodeURIComponent(p)}`;
      const download = async (p: string, to = p) => {
        const got = await get(file(p), { headers: auth });
        if (!got.ok) throw new Error(`${p}: ${got.status}`);
        const target = path.join(folder, to);
        mkdirSync(path.dirname(target), { recursive: true });
        writeFileSync(target, new Uint8Array(await got.arrayBuffer()));
      };
      const upload = async (p: string, from = p) => {
        const sent = await get(file(p), { method: "PUT", headers: auth, body: readFileSync(path.join(folder, from)) });
        if (!sent.ok) throw new Error(`${p}: ${sent.status}`);
      };
      for (const step of plan(local, remote, state[project.id] ?? {})) {
        if (step.do === "upload") await upload(step.path);
        else if (step.do === "download") await download(step.path);
        else if (step.do === "delete-remote") await get(file(step.path), { method: "DELETE", headers: auth });
        else if (step.do === "delete-local") rmSync(path.join(folder, step.path), { force: true });
        else {
          // this computer's goes beside under another name, on both sides; the server's takes its place
          const mine = conflictName(step.path, o.name);
          renameSync(path.join(folder, step.path), path.join(folder, mine));
          await upload(mine);
          await download(step.path);
        }
        o.log?.(`project ${project.path}: ${step.do} ${step.path}`);
      }
      state[project.id] = localSums(folder);
    } catch (err) {
      o.log?.(`project ${project.path}: ${err instanceof Error ? err.message : String(err)}`);
    }
  }
  writeFileSync(o.stateFile, JSON.stringify(state));
}

/** A loopback server is this computer's own: its folders are the projects' folders already, nothing to copy. */
export const sameComputer = (server: string) => {
  try {
    const host = new URL(server).hostname;
    return host === "localhost" || host === "127.0.0.1" || host === "[::1]" || host === "::1";
  } catch {
    return false;
  }
};
