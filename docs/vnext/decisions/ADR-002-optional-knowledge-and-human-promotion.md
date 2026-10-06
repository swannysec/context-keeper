# ADR-002: Optional knowledge and human-reviewed promotion

Status: accepted intended design; implementation pending. Date: 2026-10-06.

Project state stays lightweight. General knowledge is an optional Markdown workspace under lowercase `context-keeper/` in an Obsidian vault, with knowledge/projects/proposals/_system. Stable identity, provenance, status and typed wikilinks preserve durable meaning without a graph database.

Agents proactively identify candidates; humans approve authoritative promotion. Deferred proposals remain non-canonical and excluded from canonical Hindsight imports. Approval state is separate from lifecycle status. Reconciliation uses scope/status/authority/time/provenance, records the current-task interpretation and preserves meaningful history.

Rejected: mandatory second-brain services, automatic inference promotion, destructive overwrite of historical facts, and a persistent conflict database. Consequence: review/ingestion exclusion tests and graceful behavior without a workspace are required.
