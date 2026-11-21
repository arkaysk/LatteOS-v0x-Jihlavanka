// LatteOS (ADR 0202): an agent on one of this computer's own models waits for the router to load it (none is loaded
// until asked, as in LM Studio). While it loads, the bar at the foot of the conversation says so with how far it is.
import { useLatteosLocalProgress, useLatteosMcp, useModels } from "@agenteschat/client";
import { useRef } from "react";
import { useOrg } from "@/components/org-context";

/** An endpoint model's own id from its full one (`custom:<key>:<model>`); null for any other model. */
const endpointModel = (id: string | undefined) => (id ? (/^custom:[^:]+:(.+)$/.exec(id)?.[1] ?? null) : null);

/** The model an agent at work waits for and how far it is loaded (the highest seen: the estimate may step back). */
export function useLocalModelLoad(agentModel: string | undefined, working: boolean) {
  const { org } = useOrg();
  const here = useLatteosMcp(org.id).data?.localModels;
  const model = here && working ? endpointModel(agentModel) : null;
  const progress = useLatteosLocalProgress(org.id, model).data;
  const label = useModels().data?.models.find((m) => m.id === agentModel)?.label ?? model ?? "";
  const best = useRef<{ model: string | null; percent: number }>({ model: null, percent: 0 });
  if (!model || progress?.state !== "loading") {
    best.current = { model, percent: 0 };
    return null;
  }
  if (best.current.model !== model) best.current = { model, percent: 0 };
  best.current.percent = Math.max(best.current.percent, progress.percent);
  // its name alone in the bar: the label's quantization and size are for the picker
  return { model: label.split(" · ")[0] ?? label, percent: best.current.percent };
}
