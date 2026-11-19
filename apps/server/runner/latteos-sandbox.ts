import { spawn } from "node:child_process";
import { existsSync, readdirSync } from "node:fs";
import path from "node:path";
import type { Spawn } from "./scope-gate";

/**
 * LatteOS (lensAIplan2.md F6, the user's 19. 11.): an AI CLI working in a project's folder runs in bubblewrap, so the
 * folders keep to what Claude Projects promise. A project's chat writes in its project's folder; a subproject's
 * writes in its own and only reads its project's; a sibling subproject and every other project are not there at all
 * (the projects' folder is an empty one, with only these laid back in). The rest of the computer is as it was: the
 * CLIs keep their sign-ins and the runner its files.
 */
// ponytail: the home beyond the projects stays readable; hiding it means laying each CLI's own folders back in
export const BWRAP = "/usr/bin/bwrap";

/** bubblewrap's words for a CLI started in `cwd`, or null when `cwd` is in no project (nothing to keep apart). */
export function projectSandbox(cwd: string, projects: string): string[] | null {
  const rel = path.relative(projects, cwd);
  if (!rel || rel.startsWith("..") || path.isAbsolute(rel)) return null;
  const [top, sub] = rel.split(path.sep);
  if (!top) return null;
  const project = path.join(projects, top);
  const own = sub ? path.join(project, sub) : project;
  const args = ["--dev-bind", "/", "/", "--tmpfs", projects];
  if (sub) {
    // the project to read, its other subprojects gone
    args.push("--ro-bind", project, project);
    for (const e of readdirSync(project, { withFileTypes: true }))
      if (e.isDirectory() && e.name !== sub) args.push("--tmpfs", path.join(project, e.name));
  }
  args.push("--bind", own, own, "--chdir", cwd, "--die-with-parent");
  return args;
}

/**
 * The runner's spawn for AI CLIs with the projects kept apart (`LATTEOS_PROJECTS_DIR`): one started in a project's
 * folder runs in bubblewrap, the rest as before. Without the folder or bubblewrap, `inner` as it is.
 */
export function withProjectSandbox(inner: Spawn | undefined): Spawn | undefined {
  const projects = process.env.LATTEOS_PROJECTS_DIR?.trim();
  if (!projects || !existsSync(BWRAP)) return inner;
  const run: Spawn = inner ?? ((file, args, options) => spawn(file, args, options));
  return (file, args, options) => {
    const box = typeof options.cwd === "string" ? projectSandbox(options.cwd, projects) : null;
    return box ? run(BWRAP, [...box, "--", file, ...args], options) : run(file, args, options);
  };
}
