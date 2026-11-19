import { createFileRoute } from "@tanstack/react-router";
import { Main } from "@/components/Main";
import { ProjectPage } from "@/pages/ProjectPage";

/** LatteOS: a project's page (a category as Claude Projects' project): its chats, instructions, Context. */
export const Route = createFileRoute("/org/$orgId/projects/$categoryId")({
  component: function Page() {
    return (
      <Main>
        <ProjectPage categoryId={Route.useParams().categoryId} />
      </Main>
    );
  },
});
