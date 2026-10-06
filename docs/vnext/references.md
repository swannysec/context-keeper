# References and verification limits

Verified 2026-10-06 unless noted. External pages are mutable; refresh and pin relevant versions before implementation. Repository inspection establishes current code facts; documentation research establishes documented contracts, not live integration success.

| Source | Conclusion / implication |
|---|---|
| [Context Keeper repository](https://github.com/swannysec/context-keeper/tree/564d419f0a1f3f38782ebf4d4cb5c04dd269d2f7) | v1.4.0 baseline; legacy paths persist in code despite `.ai` prose. No root resolver implemented by this bootstrap. |
| [Root/schema code](https://github.com/swannysec/context-keeper/blob/564d419f0a1f3f38782ebf4d4cb5c04dd269d2f7/core/memory/schema.md) | Current schema says legacy first; vNext intends explicit → new → legacy → create new. |
| [Session start](https://github.com/swannysec/context-keeper/blob/564d419f0a1f3f38782ebf4d4cb5c04dd269d2f7/hooks/session-start.sh) | Root/config/markers/observations/handoff paths need coordinated adaptation. |
| [Search](https://github.com/swannysec/context-keeper/blob/564d419f0a1f3f38782ebf4d4cb5c04dd269d2f7/tools/memory-search.sh) | Cross-project discovery is legacy-only and bounded to configured paths; preserve privacy/scope. |
| [Hermes memory providers](https://github.com/NousResearch/hermes-agent/blob/main/website/docs/user-guide/features/memory-providers.md) | Hindsight uses native plugin/provider lifecycle; Context Keeper uses files/instructions, not the provider slot. |
| [Hindsight Hermes integration](https://hindsight.vectorize.io/sdks/integrations/hermes) | Upstream integration linked by Hermes; supported context/tools/hybrid modes and tag/bank configuration need version-pinned verification before setup. |
| [QMD](https://github.com/tobi/qmd) | Derived index of source files; canonical state must survive index loss. |
| [Hindsight](https://github.com/vectorize-io/hindsight) | Derived cognition/experiential retention; approval and source provenance remain explicit in canonical files. |

Platform-specific primary sources and remaining limits live in [agent namespaces](agent-namespaces.md). Companion runtime/wrapper references contain operational integration details; Context Keeper's base package does not require them.

## Background context boundary

The available bounded preview and `read_thread` retrieval from “Hermes Agent Hosting Options” were inspected first. Available recent turns confirm the three workstreams, wrapper independence, contextual reconciliation and Git targets. The retrieved older bootstrap response was itself truncated, and the API returned no older cursor; complete conversation recovery is not claimed. The explicit current handoff supplies intended requirements. Background chat is supplementary and is not a repository authority or a verification source for upstream behavior.

## Observed dependency source heads

The GitHub API reported Hermes `cd94de7ea428b74a6f1de6400ad3837f5d349b39`, OpenShell `8760396975f4b0f13cd6fd88ac1a46342ee84343`, Hindsight `9269b88417ed263e5a8350f2e416ca2b322756b1`, and QMD `93d211f9ef4a869a9aed0d075ca767dda552627f` on 2026-10-06. These are retrieval anchors, not empirically tested deployment pins. Context Keeper behavior is anchored to its full source revision above.
