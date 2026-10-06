# Identity, provenance, relations and time

Status: normative requirements; the example serialization is proposed for Phase 5 review.

Canonical knowledge remains Markdown. Metadata should include stable ID, type, title, aliases, tags, created/updated time and lifecycle status. Stable IDs identify a note even when its filename/title changes; duplicate IDs must be diagnosed. Human-readable wikilinks must remain usable without a graph database; an optional index can resolve ID-to-path mappings and be rebuilt.

Typed relations may be expressed as `secures [[Hermes Agent]]`, `works_at [[Company]]`, `supersedes [[Previous Decision]]`, or `replaced_by [[New Decision]]`. Relation vocabulary and sub-taxonomies remain extensible. Renames must retain identity and update/resolve links deliberately; ambiguous titles are not evidence that two entities are identical.

```yaml
---
id: example-stable-id
type: decision
title: Example decision
aliases: []
tags: []
created: 2026-10-06T00:00:00Z
updated: 2026-10-06T00:00:00Z
status: current
valid_from: 2026-10-06
sources:
  - type: repository
    identifier: example/repo@revision:path
    captured_at: 2026-10-06T00:00:00Z
proposal:
  agent: example-agent
approval:
  state: approved
  reviewer: example-human
  reviewed_at: 2026-10-06T00:00:00Z
---
```

This is illustrative, not a shipped parser contract. Do not fabricate capture time, reviewer, approval or source identifiers. When unavailable, record the uncertainty; distinguish capture time from the event's effective time. Existing plain Markdown without metadata must remain readable.

Lifecycle statuses: `current`, `superseded`, `disputed`, `deprecated`. Approval state is separate: an agent's proposal may describe a current claim but remains non-canonical until reviewed. Source evidence, proposing agent and human approval are distinct fields/concepts. Retain historically meaningful claims with validity intervals and supersession relations; an update timestamp alone does not prove a newer authoritative fact.

Hindsight inference may identify a possible stale claim or entity relation; it is evidence for review, not an approval event. Retrieval should default to eligible current state while allowing intentional historical queries with provenance and status visible.
