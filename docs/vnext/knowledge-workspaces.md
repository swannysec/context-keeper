# Optional Knowledge Workspaces

A Knowledge Workspace stores approved general knowledge about people, organizations, technologies, concepts, research, cross-project facts and durable relationships. It supplements project memory; it does not redefine ordinary project state or require Obsidian.

For an Obsidian vault, managed content lives under lowercase `<vault>/context-keeper/`:

```text
context-keeper/
  knowledge/
  projects/
  proposals/
  _system/
```

`knowledge/` holds approved durable notes with user-extensible taxonomies. `projects/` holds deliberately promoted project knowledge or explicit links to project state, not an automatic shadow copy of every project. `proposals/` holds non-canonical pending/deferred review material. `_system/` holds workspace metadata/indexes; an index is navigation, not another authority store.

Workspace path is explicitly configured. Do not guess a Google Drive/Obsidian path from the developer machine. With no configured workspace, base behavior continues. If the workspace is unavailable, diagnose reachability and preserve pending work locally without silently choosing a different canonical destination. Decide offline proposal placement explicitly before implementation.

Mac-side vault content is authoritative in the OpenShell deployment. Mirrors must preserve edits and signal conflicts; filesystem permissions, not sync direction, govern Hermes access. Context Keeper does not own transport or start a sync daemon. The runtime repo owns that unresolved mechanism.

QMD may index reviewed source collections for retrieval. Canonical Hindsight imports must use approved/current eligible notes with provenance; proposals must be excluded, including renamed or misplaced pending notes by approval metadata as well as directory rules. Historical/superseded notes can be retrieved deliberately in a separate scope. Private material must not be exported/indexed into a broader scope merely because it shares a vault.
