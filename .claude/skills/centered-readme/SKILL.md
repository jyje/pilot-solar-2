---
name: centered-readme
description: Format a README's header as a centered hero block (title, optional logo, tagline, badges, language links) matching the style jyje uses across his own repos. Use when creating a new README from scratch, or asked to restyle/center an existing one.
---

# Centered README header

jyje's own repos (not forks of someone else's project) share a common README
header pattern: everything above the first real section is wrapped in a
centered block; the rest of the document stays normally left-aligned.

## Template

```markdown
<div align="center">

# <owner>/<repo>

<!-- center logo, omit entirely if no single icon represents the project -->
<img width="<150-250>" src="<logo-url>" alt="<Tech>" title="<Tech>"/>

<One-line tagline/description>

[![badge 1](...)](...)
[![badge 2](...)](...)

[English](<path>) / [한국어](<path>)

</div>

<intro paragraph, or a "found this useful? ⭐" call-to-action, or nothing —
dive straight into the next heading>
```

## Choosing what to include

- **Logo** — one relevant tech/brand icon. Two related logos can be combined
  with a "+" between them when the project genuinely spans two
  technologies/brands. Width 96-250px depending on the logo's aspect ratio.
  Skip it entirely rather than inventing a placeholder icon for a project
  with no obvious single logo. Prefer a stable, version-pinned source over
  linking to an arbitrary external domain — a personal site/blog can go
  down, get redesigned, or change its asset paths, silently breaking the
  image. Good sources, in order of preference:
  - `raw.githubusercontent.com` URL pinned to a branch/path in a repo you
    control
  - [Lobe Icons](https://icons.lobehub.com) via its versioned CDN URL, e.g.
    `https://unpkg.com/@lobehub/icons-static-svg@<version>/icons/<name>.svg`
    (pin `<version>`, don't use `@latest`, so the image doesn't shift under
    you) — good coverage of AI/LLM/dev-tool brands
- **Badges** — only ones that are actually true for this repo:
  - CI/release workflow status: `https://github.com/<owner>/<repo>/actions/workflows/<file>.yaml/badge.svg`
  - GitHub stars: `https://img.shields.io/github/stars/<owner>/<repo>?style=social`
  - License: `https://img.shields.io/badge/License-<name>-yellow.svg` (only if a `LICENSE` file exists)
  - Package registries (Artifact Hub, npm, PyPI, ...) via their own badge endpoints
- **Language links** — only if the repo genuinely ships more than one
  language's docs (e.g. `README.md` / `README-ko.md`). In a repo where only
  the root README is bilingual and every other doc is English-only, put the
  language link only on that root README — don't add it to docs that have
  no translated twin.
- **After the closing `</div>`** — either dive straight into the next
  heading (`## Overview` / `## Summary`), or add a one-line star-ask first.

## Steps

1. Identify the repo's real name, a 1-2 line tagline, and any logo/badges
   that are genuinely applicable — don't add a badge for a workflow or
   license that doesn't exist yet.
2. Wrap that header in `<div align="center">...</div>` per the template.
3. Leave the rest of the README's body left-aligned and unchanged — only the
   header block is centered.
4. Re-render/preview if possible (GitHub markdown preview, or `make docs` if
   the README is templated) before considering it done.
