# format-spec.md

The exact schema for every `SKILL.md` and `overview.md` file w2s
produces. Load this file before writing any output. If your output
deviates from this schema, the skill will not be portable across
agents.

There are two file types: `overview.md` (one per domain) and
`SKILL.md` (one per route family). Both are markdown with YAML
frontmatter.

---

## 1. `overview.md`

One `overview.md` per unique registrable domain. This is the agent's
entry point for the site — it is loaded first, then the per-route
skill is loaded as needed.

### Frontmatter

```yaml
---
name: <skill-name>            # required, kebab-case, no dots
domain: <example.com>         # required, registrable domain
description: |                # required, 1-3 sentences
  Plain-language description of what the site is and what the agent
  can do on it. Used by the agent's skill loader to decide when to
  load this skill.
match:                        # required, list of URL patterns
  - <example.com>
  - <example.com/*>
requires: []                  # optional, list of other skill names this depends on
---
```

Notes:

- `name` MUST be a stable, short identifier. For `github.com` use
  `github`. For `app.linear.app` use `linear`. Never include the
  TLD.
- `match` is a list of glob-style patterns. The agent matches the
  current URL against this list to decide which skill to load. Keep
  it broad — fine-grained matching belongs in the per-route file.
- `description` is what the agent uses for routing. Make it
  informative but concise. Bad: "A website." Good: "Use github.com
  to navigate repositories, manage issues and PRs, star/watch repos,
  and configure settings."

### Required sections

In order:

1. `# <Skill Name> — Site Map` — H1 title
2. `## How to navigate` — 2-5 sentences on the site's structure
3. `## Route map` — a mermaid graph (see below) plus a bullet list
4. `## Sub-skills` — list of route families and which file handles
   each
5. `## Site-wide patterns` — persistent header, footer, global nav,
   modals that appear on every page
6. `## Identity model` — how to detect logged-in vs logged-out
   state, where the auth entry point is

### The route map mermaid graph

A mermaid `graph TD` block showing how the main routes connect.
Edges represent user actions (clicking a tab, following a link, etc.).
Labels on edges should be short verb phrases ("click Issues tab",
"submit form").

```mermaid
graph TD
    Home[github.com] -->|click repo link| Repo[/:owner/:repo]
    Repo -->|click Issues tab| Issues[/:owner/:repo/issues]
    Repo -->|click PR tab| PRs[/:owner/:repo/pulls]
    Issues -->|click issue title| IssueView[/:owner/:repo/issues/:n]
    IssueView -->|click New Issue| NewIssue[/:owner/:repo/issues/new]
```

Keep the graph to the 5-10 most important routes. Do not draw every
edge; the agent can read the per-route files for the rest.

### The sub-skills list

A bullet list mapping route patterns to files:

```markdown
## Sub-skills
- `repo.md` — matches `/:owner/:repo` (the repository main page)
- `issues.md` — matches `/:owner/:repo/issues` and
  `/:owner/:repo/issues/:n`
- `pulls.md` — matches `/:owner/:repo/pull/:n`
- `settings.md` — matches `/:owner/:repo/settings/*`
```

Each file name must match an actual file in the same directory. Each
match pattern must correspond to a real route family the user gave
you.

---

## 2. `SKILL.md` (per route)

One `SKILL.md` per route family. Loaded by the agent when the current
URL matches the file's `match` field.

### Frontmatter

```yaml
---
name: <route-skill-name>      # required, kebab-case
description: |                # required, 1-3 sentences
  What this route is and what the agent can do on it.
match:                        # required, list of patterns or regexes
  - /^https:\/\/github\.com\/[^/]+\/[^/]+\/issues(\/.*)?$/
requires:                     # optional, other skills required first
  - <overview-skill-name>
---
```

Notes:

- `name` is the route skill's name. For the issues page of github,
  use `github-issues` or just `issues` (the file is in a domain
  folder so the name does not need to be globally unique, but
  keeping the domain prefix avoids collisions if a user copies a
  single file).
- `match` can be globs OR regexes. Regexes are preferred for
  parameterized URLs (issues with IDs, repos with owner/name, etc.).
  Always anchor regexes with `^` and `$`.
- `requires` should list the overview skill if the overview has
  site-wide information the agent needs (header, identity model,
  etc.). Example: `requires: [github]`.

### Required sections

In order:

1. `# <Site> — <Page Name>` — H1 title
2. `## Page architecture` — header, sidebar, main, footer, with
   what's in each
3. `## Element inventory` — every interactive element, with refs
4. `## Workflows` — 3-7 common tasks
5. `## Edge cases` — modals, auth walls, empty states, etc.

### Page architecture

A short prose section describing the page layout. Use named regions
(header, sub-header, left rail, main column, right rail, footer).
Each region gets a short description of what's in it. Reference
elements by their `ref` (see Element inventory below).

```markdown
## Page architecture

- **Header (inherited from overview):** standard GitHub header with
  search, notifications, avatar
- **Sub-header:** repo name + Issues / Pull requests / Code / Settings
  tabs
- **Left rail (260px):** filters — Open/Closed toggle at top, then
  Labels, Milestones, Assignees, Author, Projects, Sort
- **Main column:** list of issues, each row showing title, number,
  author, labels, last-updated timestamp
- **Right rail:** "New issue" button (green) at the top of the
  main column
```

### Element inventory

Every interactive element on the page gets a `ref` (a stable name
the workflows reference) and a structured description. Element refs
are kebab-case, descriptive, and unique within the file.

```markdown
### `<ref-name>`

- **type:** button | link | input | textarea | select | checkbox |
  radio | tab | list-item | repeatable | container | other
- **selector:** `<CSS selector>` — primary, prefer `[data-testid=...]`
  or stable IDs
- **fallback:** `<aria or text-based selector>` — for when the primary
  fails; typically `role=<role>[name="<label>"]` or text="..."
- **location:** `<where on the page>` — short prose, e.g.
  "top-right of main column, green"
- **contains:** `<list of child refs>` — only for container and
  repeatable types
```

Examples:

```markdown
### `new-issue-btn`

- **type:** button
- **selector:** `a[href$="/issues/new"]`
- **fallback:** text="New issue"
- **location:** top-right of main column, green

### `issue-row`

- **type:** repeatable
- **selector:** `[data-testid="issue-row"]`
- **fallback:** `role=listitem` containing a link with text matching
  the issue title
- **location:** each row in main column
- **contains:** `issue-title`, `issue-number`, `issue-labels`,
  `issue-author`
```

Selector quality rules:

- **Best:** `[data-testid="<name>"]`, `[aria-label="<exact>"]`,
  `#<stable-id>`. These survive redesigns.
- **Good:** semantic selectors like `nav a[href="/pricing"]`,
  `form input[name="email"]`. Use when test IDs are absent.
- **Acceptable:** `button:has-text("Sign in")`,
  `role=button[name="Sign in"]`. Last resort because text can change.
- **Forbidden:** positional selectors (`div > div > a:nth-child(3)`),
  random class hashes (`.css-1a2b3c`, `.jsx-12345`), auto-generated
  framework classes. If the only selector you can find is a hash,
  do not document that element.

### Workflows

A workflow is a sequence of steps the agent follows to accomplish a
task on this page. Workflows reference elements by `ref` (in
backticks). They do NOT include executor-specific code — that is
the job of the runtime, not the skill.

```markdown
## Workflows

### <verb> <object>

1. Confirm on route `<expected URL pattern>`
2. Click `<element-ref>` (or: Type `<text>` into `<element-ref>`)
3. Verify: <observable outcome that confirms success>
4. If <error condition>, <recovery action>

### Create a new issue

1. Confirm on route `/owner/repo/issues`
2. Click `new-issue-btn`
3. Type the issue title into the input labeled "Title"
4. Type the issue body into the textarea labeled "Leave a comment"
5. Click "Submit new issue" at the bottom of the form
6. Verify: URL changes to `/owner/repo/issues/N`, page shows the
   new issue title
7. If the title field is empty when you click submit, an error
   "Title is required" appears below the field — fill the title
   and retry
```

Workflow rules:

- Each step is one concrete action the agent takes. No compound
  steps ("fill out the form" is too vague; break it down).
- Steps that interact with an element reference it by `ref` in
  backticks: `Click \`new-issue-btn\``.
- Steps that type/fill say what to type: `Type "Hello" into
  \`comment-input\``.
- The last step is almost always a verification — how does the
  agent know the workflow succeeded?
- Edge cases the agent is likely to hit get an "If X, then Y"
  sub-step at the end of the workflow.
- Workflows are written for the agent, not for humans. Use
  imperative voice, not chatty explanations.

### Edge cases

Document anything that can vary based on state, auth, or timing.
Categories to consider:

```markdown
## Edge cases

- **Empty state:** when there are no issues, main column shows
  "Welcome to issues! ... Sign up for free" or "No results"
  depending on auth state
- **Auth wall:** "Sign in" link at top-right when logged out
- **Loading state:** filter changes briefly show a spinner; wait
  for the list to re-render before reading
- **Rate limiting:** after N actions, GitHub may show a CAPTCHA;
  pause and ask the user to solve it
- **Drafts:** drafts are filtered out by default; to see them,
  click "Your issues" in the filter rail
```

If a category does not apply to this page, omit it. Do not pad.

---

## 3. Validation

Before saving any output, verify against the checklist in `SKILL.md`
Step 7. A skill that fails validation is worse than no skill — it
will lead the agent astray and waste tokens.