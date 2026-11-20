# 0201. LatteOS: anonymous projects, and more project kinds

- Status: Accepted (built)
- Date: 2026-11-20
- Extends: 0151 (who sees a channel: administrators read every channel, never a DM), 0017 (search index), 0023 (wiki),
  0167 (memory), 0190 (a confidential thread keeps what it read)
- Code: `packages/engine/src/anonymous.ts`, `channel-categories.ts`, `channels.ts`, `task-access.ts`
  (`adminChannelSql`, `channelReaderSql`), `tools/gateway.ts`, `context.ts` (`projectBrief`), `executor.ts`,
  `context/tools.ts` (`remember`, `update_memory`, `forget`), `context/summaries.ts`, `context/learn.ts`,
  `thread-assess.ts`, `search.ts`, `notification-producers.ts`, `approvals.ts`; schema `channel_categories.anonymous`
  and the `channel_project_type` values; migrations `0311_latteos_more_project_kinds.sql`,
  `0312_latteos_project_anonymous.sql`; web `components/project/KindPicker.tsx`, `kinds.ts`, `pages/ProjectPage.tsx`;
  tests `packages/engine/test/latteos-anonymous.test.ts`

## Context

LatteOS runs this server on the person's own computer and uses its categories as projects, each with a folder. A
project may be offline (the folder only here) or online (a copy on the server and every computer). A third kind of
project was asked for: the same as offline, but private to its creator, with its memory in a Markdown file instead of
the wiki, never reaching anything else.

## Decision

1. **Mode.** `channel_categories.anonymous` (default false), beside `online`. The creator is `created_by_user_id`.
   Anonymous implies not online (no sync, no git history); an online project is not switched to Anonymous directly
   (`project.anonymous_online_first`: Offline first), and what an earlier online time left stays: the server's history
   and the copies on other computers. A subproject has its project's value: making a project
   anonymous (only its creator may, and only a project with a kind and a folder) applies to its subprojects, a subproject
   cannot be made non-anonymous alone, and an anonymous project does not move. Switching back out is allowed (the
   creator only): the marker file goes away; `MEMORY.md` stays in the folder and nothing is copied into the database. The
   chats stay private to the creator.
2. **Needs the server's own folder.** `LATTEOS_PROJECTS_DIR` must be set (a server elsewhere refuses with
   `project.anonymous_needs_folder`). The server writes `MEMORY.md` itself and puts `.agentgram-anonymous` in the folder
   of the project and of every subproject, so programs that index the folders can skip them.
3. **Access.** Only the creator. For anyone else the project, its subprojects and its chats do not exist: the category
   list leaves them out, the category routes answer 404, `requireChannelAccess` answers 404 and `joinChannel` too. The
   one rule that let administrators read every channel (`adminChannelSql`, `channelReaderSql`, and the places that spelled
   it out: the channel list and card, mentions, threads, the team's week, agents' places) excludes them. Its chats are
   private, with no role audience, and only the creator in them; moving a chat into the project, or making the project
   anonymous, takes everyone else out, other people and every agent (the creator adds the agents they want, and only they
   can). Approvals of runs there are listed, decided and asked of the creator alone.
4. **Memory is a file.** In a run whose chat is in an anonymous project, `remember` (any `for`) appends a line to the
   `MEMORY.md` of the chat's own (sub)project; `update_memory`/`forget` say memory is the file; the project's page reads
   and writes the file in place of `channel_categories.memory`. Nothing is written to `context_items`. The wiki tools,
   search, summaries, Drive, issues, calendar, schedules, vault, setup, `post_message`/`send_dm`/`post_update`,
   `ask_agent`/`tell_agent`/`hand_off`, status, dashboards, feedback and the how-to/instruction proposals are not offered
   to such a run and are refused with a clear message if called (`refusedInAnonymous`). Nothing is derived from its
   chats: no thread summary, period summary, reflection (decisions, profiles), learning, thread title and status line.
5. **Separated both ways.** A run there reads its own `MEMORY.md` (the project's, read only, for a subproject), the
   project's instructions and its folder; not the team's memory, wiki pages, the agent's memory, rules, other
   conversations (`agentSearchChannels` is the chat itself), tasks, hand-offs or work of other conversations. What stays
   is configuration, not memory: the organization's plain instructions text and the agent's own role and instructions.
6. **Never out.** Closed: the search index and so the embeddings provider (`indexSource`, `upsertWithEmbeddings` and
   every reindex), notifications (the inbox only, with no text as for a confidential thread, and no push or email
   at all), approvals' lists, the second model calls of the run (status line), the lists of
   administrators, the team's week, the operator API's content reads (there are none), exports (public channels and
   no messages), the Drive across channels and sharing (tools refused). Online sync and git history never include it.
7. **Inherent.** The agents' own model calls: whatever an agent reads in the chat goes to the AI provider it thinks
   with (and the cheap models that route and choose its tools read the message), or the chat could not be answered.
   The project's page says so. Connected apps' (MCP) tools of the workspace are not offered and are refused there; the agent's own
   local tools on its computer stay. A project's name may show in the error "already exists"
   to someone who picks the same name in the same place.
8. **Encryption** of the folder or the file is left out for now.

## Project kinds

The kinds grow from 7 to 26 (new migration, the old values kept): writing, research, study, video, photo, animation,
game, web, app, design, podcast, data, business, marketing, finance, home, travel, event, health. Each kind has an icon
of the design system's own set and its own colour: the tile derives its two themes with the workspace accent's rule
(`accentPalette`), so the icon reads at 4.5:1 on its soft tile and on the page, in light and in dark. The picker is a
grid of these tiles.
