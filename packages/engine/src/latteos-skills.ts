import { createHash } from "node:crypto";
import { lstatSync, readdirSync, readFileSync, realpathSync } from "node:fs";
import path from "node:path";
import { and, eq, isNull, schema } from "@agenteschat/db";
import { NotFoundError, ValidationError } from "./errors";
import { latteosSkillsDir } from "./latteos";
import { requirePermission } from "./organizations";
import { parseSkillMarkdown, repositorySkill, SKILL_LIMITS, type SkillDeps, saveSkill } from "./skills";

/**
 * Skills of this computer (ADR 0202): the folders under `LATTEOS_SKILLS_DIR` that hold a SKILL.md. Read here, on the
 * server's own disk; nothing that resolves outside the folder is followed.
 */
export interface LatteosSkillRow {
  folder: string;
  name: string;
  description: string;
  /** `new`: not installed; `installed`: as it is on the disk; `update`: the folder changed since. */
  state: "new" | "installed" | "update";
  skillId: string | null;
}

interface Walked {
  /** The folder's real path. */
  root: string;
  files: [string, { size: number; abs: string; mtime: number }][];
}

const FOLDER = /^[A-Za-z0-9][\w.-]{0,100}$/;

/** A folder of the skills' folder, resolved: it must stay inside it, whatever links it passes. */
function skillFolder(base: string, folder: string): string | null {
  if (!FOLDER.test(folder)) return null;
  try {
    const root = realpathSync(base);
    const real = realpathSync(path.join(root, folder));
    return real.startsWith(`${root}${path.sep}`) && lstatSync(real).isDirectory() ? real : null;
  } catch {
    return null;
  }
}

/** Every file of a skill folder: a link is followed only when it ends inside the folder itself. */
function walk(root: string): Walked {
  const files: Walked["files"] = [];
  const visit = (dir: string, rel: string, depth: number) => {
    if (depth > 8) return;
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      if (files.length > SKILL_LIMITS.maxFiles) throw new ValidationError("The skill has too many files");
      const abs = path.join(dir, entry.name);
      let real: string;
      try {
        real = realpathSync(abs);
      } catch {
        continue;
      }
      if (real !== root && !real.startsWith(`${root}${path.sep}`)) continue;
      const st = lstatSync(real);
      const name = rel ? `${rel}/${entry.name}` : entry.name;
      if (st.isDirectory()) visit(real, name, depth + 1);
      else if (st.isFile()) files.push([name, { size: st.size, abs: real, mtime: Math.floor(st.mtimeMs) }]);
    }
  };
  visit(root, "", 0);
  return { root, files };
}

/** What the folder holds now, cheaply: its files' names, sizes and times (`skills.source_hash` keeps it). */
const signature = (w: Walked) =>
  createHash("sha256")
    .update(JSON.stringify([...w.files].sort((a, b) => (a[0] < b[0] ? -1 : 1)).map(([p, f]) => [p, f.size, f.mtime])))
    .digest("hex");

function describe(base: string, folder: string) {
  const root = skillFolder(base, folder);
  if (!root) return null;
  try {
    const text = readFileSync(path.join(root, "SKILL.md"), "utf8").slice(0, 100_000);
    const parsed = parseSkillMarkdown(text);
    return { root, name: parsed.name, description: parsed.description };
  } catch {
    return null;
  }
}

/** The skills on offer, each with where it stands in the workspace. */
export async function listLatteosSkills(deps: Pick<SkillDeps, "db">, actorId: string, orgId: string) {
  const base = latteosSkillsDir();
  if (!base) return { enabled: false as const, skills: [] as LatteosSkillRow[] };
  await requirePermission(deps.db, actorId, orgId, "read");
  const mine = await deps.db
    .select({ id: schema.skills.id, metadata: schema.skills.metadata, hash: schema.skills.sourceHash })
    .from(schema.skills)
    .where(and(eq(schema.skills.orgId, orgId), isNull(schema.skills.deletedAt), isNull(schema.skills.ownerUserId)));
  const installed = new Map<string, { id: string; hash: string | null }>();
  for (const s of mine) {
    const from = (s.metadata as { latteos?: unknown } | null)?.latteos;
    if (typeof from === "string") installed.set(from, { id: s.id, hash: s.hash });
  }
  let folders: string[] = [];
  try {
    folders = readdirSync(base)
      .filter((f) => FOLDER.test(f))
      .sort();
  } catch {
    return { enabled: true as const, skills: [] as LatteosSkillRow[] };
  }
  const rows: LatteosSkillRow[] = [];
  for (const folder of folders) {
    const found = describe(base, folder);
    if (!found) continue;
    const have = installed.get(folder);
    const now = have ? signature(walk(found.root)) : null;
    rows.push({
      folder,
      name: found.name,
      description: found.description.slice(0, 400),
      state: !have ? "new" : have.hash === now ? "installed" : "update",
      skillId: have?.id ?? null,
    });
  }
  return { enabled: true as const, skills: rows };
}

/** Installs a folder of this computer as the team's skill (a new version when it is installed already). */
export async function installLatteosSkill(deps: SkillDeps, actorId: string, orgId: string, folder: string) {
  const base = latteosSkillsDir();
  if (!base) throw new NotFoundError("No skills folder on this server");
  await requirePermission(deps.db, actorId, orgId, "manage_agents");
  const root = skillFolder(base, folder);
  if (!root) throw new NotFoundError("That skill is not in the skills folder");
  const walked = walk(root);
  const skill = await repositorySkill(
    async (entry: { abs: string }) => new Uint8Array(readFileSync(entry.abs)),
    "",
    walked.files,
  );
  return saveSkill(deps, actorId, orgId, {
    ...skill,
    metadata: { ...skill.metadata, latteos: folder },
    source: "upload",
    sourceHash: signature(walked),
    owner: null,
  });
}
