ADM notes serve project logistics: tasks, planning, open items, status overviews and organizational workflows.
ADM helps to steer the project. It is not technical documentation of the system.


## Goal
- Centrally manage ToDos and open items
- Make progress visible (What is open, what is blocked, what is finished)
- Keep next steps and priorities clear
- Support project organization (deadlines, submissions, procurement, contacts)


## What belongs in ADM
Typical content:
- ToDo lists (brief, prioritized)
- Backlog / idea parking lot
- Weekly plan / sprint plan (if used)
- Risk/blocker list (What prevents progress)
- Purchase/procurement lists
- Contacts, deadlines, submissions (organizational only)
- Checklists for project milestones (e.g. "demo-ready", "submission-ready")
- Status dashboards (e.g. "Top 10 open items")
- Trackers: the state of things that leave the project — a patch sent upstream, a pull request, a submission, an order


## Lifecycle state lives in one tracker row
Lifecycle state is the state of an external action or of a plan step after the work itself is done: sent, pushed, merged, published, approved, a phase or round state. It changes long after the evidence and the decision were written, so it is written in exactly one place — the row of the ADM tracker that tracks the item.

- Every other note links the tracker and names the role, never the state: a TAE writes "Upstream state: \[\[ADM_Upstream_Tracker]]", not "nothing has been sent yet". A TAE states what was tested; whether its result was sent or merged is the tracker's.
- An item has one live row across all trackers. When it moves to another tracker — a candidate becomes a contribution — its old row goes to the old tracker's `_Closed` sibling with the state `promoted` and a link to the new tracker.
- A note's own status is not lifecycle state and stays where it is: the frontmatter `status`, a DEC's `Status:` line, the status column of an ARC allocation row.


## Tracker shape
One tracker per kind of tracked thing (contributions, orders, submissions), one row per item:

| Item | State | Since | Next step | Detail |
| --- | --- | --- | --- | --- |
| Battery log rotation fix | sent | 2026-10-01 | Answer review comments inline. | \[\[TAE_Battery_Log_Rotation]] |

- **State and Since are replaced, never appended.** The previous state is in the git log of the commit that changed the row.
- **Next step is one sentence.** A cell that grows into a dated account of what happened is a log; the log is git, the evidence is the TAE, the reasoning is the DEC — link them in the Detail column.
- **No dated follow-up sections and no session log.** "Follow-ups from the check of 2026-10-13" appended below the table is the same log in a different place. Open follow-ups are rows; findings of a check are its TAE.
- **A plan keeps one short status cell per phase**, under the same rules.


## Finished rows leave
In the session that finishes an item — merged, rejected, delivered, abandoned — its row leaves the tracker:

1. Move the row to a sibling note named after the tracker with the suffix `_Closed` (e.g. `ADM_Upstream_Tracker_Closed`), reduced to final state, date and the Detail link. The suffix may be written in the vault's language.
2. The tracker's Context links its `_Closed` sibling, so the closed note is reachable and every row stays findable.
3. Search the vault for notes linking the tracker about this item and bring them along (Freshness rule of the conventions file).
4. When the `_Closed` note itself reaches the length warning, split it by year (`ADM_Upstream_Tracker_Closed_2026`).

The tracker answers "where does each open item stand?", the `_Closed` note "how did each finished item end?" — two questions, two files.


## Recommended ADM Files (minimal, effective)
- ADM_TODO (central ToDo list)
- ADM_Backlog (ideas / later)
- ADM_Blocker (current standstill + what is missing)
- ADM_Milestones (submissions, demo, review)
- ADM_Procurement (orders, delivery status)
- `ADM_<Kind>_Tracker` and `ADM_<Kind>_Tracker_Closed` (state of things that leave the project)

ADM has no file template on purpose: the shape above is a convention for trackers, not a set of sections every ADM note owes.
