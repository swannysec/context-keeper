# Security Guidelines

## Overview

ConKeeper stores project context in plain Markdown files. While this provides transparency and version control compatibility, it requires users to be mindful of what information they store.

## What NOT to Store in Memory Files

**Never store these in `.claude/memory/` files:**

- API keys, tokens, or secrets
- Passwords or credentials
- Private keys or certificates
- Personal identifiable information (PII)
- Internal IP addresses or infrastructure details
- Proprietary algorithms or trade secrets

## Safe Storage Practices

### For Solo Projects

If you're the only contributor:
- Consider adding `.claude/memory/` to `.gitignore` for sensitive projects
- Review memory contents before pushing to public repositories
- Use environment variables for secrets, not memory files

### For Shared Repositories

If others have access to the repository:
- Always add `.claude/memory/` to `.gitignore`
- Use the `/memory-init` command and select "No" for git tracking
- Keep architectural decisions generic (no internal URLs or credentials)

### For Public Repositories

If the repository is public:
- Never commit `.claude/memory/` directory
- Review all files before making a repository public
- Consider if architectural details could aid attackers

## Memory File Locations

| Location | Purpose | Risk Level |
|----------|---------|------------|
| `~/.claude/memory/` | Global preferences | Low (user home, not in repos) |
| `.claude/memory/` | Project context | Medium (may be committed) |
| `.claude/memory/decisions/` | ADRs | Medium (architecture details) |
| `.claude/memory/sessions/` | Session history | Low (typically transient) |

## Reporting Security Issues

If you discover a security vulnerability in ConKeeper:

1. **Do not** open a public GitHub issue
2. Utilize [GitHub private vulnerability reporting](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-a-vulnerability/privately-reporting-a-security-vulnerability)
3. Include steps to reproduce the vulnerability
4. Allow reasonable time for a fix before disclosure (this is a personal project with a single maintainer)
