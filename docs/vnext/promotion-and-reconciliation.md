# Promotion and reconciliation

## Proactive promotion

Agents should identify durable-memory candidates without requiring the user to remember a command. Classify the proposed destination as project memory, global operating memory, or general knowledge. Queue routine candidates and present them at natural checkpoints; surface significant decisions/conflicts immediately when they affect the task.

Present the claim, destination, source evidence, uncertainty, impact and proposed change. Human actions are approve, edit then approve, keep project-only, defer and reject. Record the actual choice; no response is not approval. An explicit request to save a specified fact can be reviewed authorization for that fact, not blanket approval of unrelated proposals.

Deferred general-knowledge proposals live in `context-keeper/proposals/`. Pending proposals are non-canonical and must not be ingested as canonical Hindsight knowledge or mixed with current approved retrieval. Rejection prevents automatic re-proposal unless materially new evidence appears. Keep-project-only limits scope and does not authorize global/general promotion. Apply privacy protections before proposing or importing sensitive material.

Proposal metadata should record ID, candidate destination, evidence, proposing agent, capture time, review state and reviewer/action where supplied. Queue storage without a configured Knowledge Workspace is an open Phase 6 design detail; do not silently create a vault or global store.

## Reconciliation

Use **scope → status → authority → temporal validity → provenance** as contextual reasoning, not a universal precedence loop. First determine whether claims apply to the same project/entity/task and time. Separate active decisions from proposals, history and inference. Authority governs current action; recency alone does not override explicit approval, and fresh authoritative evidence can demonstrate that approved state is stale.

Detect the conflict, resolve the active interpretation for the current task, record/update canonical state through the authorized review path, then proceed. If human judgment is necessary, state the concrete conflicting claims and consequence while continuing unaffected work. Do not reopen a resolved conflict without materially new evidence.

Represent outcomes with ordinary status, validity metadata and `supersedes`/`replaced_by` relations. Preserve lower-authority/history where meaningful. There is no separate persistent conflict database. Hindsight may challenge stale state, but must not silently overwrite files. Pending unresolved claims remain visible as disputed/proposed rather than being laundered into canonical truth.

Acceptance cases: newer authoritative source invalidates old decision; recent inference conflicts with current approved decision; same wording in different projects; historic relationship valid only before a date; duplicate proposal; rejected candidate reappears without new evidence; silent user; edited approval; keep-project-only; deferred candidate never enters canonical import.
