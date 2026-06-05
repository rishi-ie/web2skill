# Using w2s skills with agent-browser

[w2s](../../README.md) generates skills. [agent-browser](https://github.com/vercel-labs/agent-browser) is the CLI tool that executes them. This document shows how the two integrate — how to compile skills using agent-browser's snapshot engine, and how to run compiled skills through agent-browser.

---

## The core mapping

w2s and agent-browser both use **element references** to identify UI elements. The difference is in format and how they're resolved:

| | w2s | agent-browser |
|---|---|---|
| **Ref format** | Named, kebab-case: `new-issue-btn`, `issue-row` | Numbered, `@eN`: `@e1`, `@e2`, `@e3` |
| **How resolved** | CSS selector stored in skill | Accessibility tree snapshot assigns refs dynamically |
| **Determinism** | High — selector is stable | High — tree is deterministic |
| **Compile time** | Refs assigned once at compile | Refs assigned per-snapshot at runtime |

The integration bridges these by **converting w2s element refs to agent-browser selectors** at runtime, using the same selectors that w2s recorded.

---

## Compiling a site using agent-browser

Use agent-browser as the distillation engine instead of a generic browser tool. The `snapshot -i` command produces an accessibility tree that you use to author the skill.

### Step 1 — Install agent-browser

```bash
npm i -g agent-browser
agent-browser install
```

### Step 2 — Open the site and take a snapshot

```bash
agent-browser open https://github.com/foo/bar
agent-browser snapshot -i
```

The `-i` flag gives you an **interactive snapshot** with numbered refs:

```
@e1  button  "Star"    (top-right of repo header)
@e2  link    "Issues"  (tabs row)
@e3  button  "Code"    (top-right, green)
...
```

### Step 3 — Interact and capture all states

Click every interactive element to find modals, dropdowns, and hover-revealed actions:

```bash
agent-browser click @e2          # Click Issues tab
agent-browser snapshot -i        # Snapshot of issues page
agent-browser click @e7          # Click New issue button
agent-browser snapshot -i        # Snapshot of modal (URL changes to /issues/new)
```

Use `--json` for machine-readable output:

```bash
agent-browser snapshot -i --json | jq '.data.refs'
```

### Step 4 — Map @eN refs to w2s element refs

Each agent-browser ref maps to a w2s element in the skill:

| agent-browser snapshot | w2s element |
|---|---|
| `@e1  button  "Star"` | `### star-btn` with selector from DOM |
| `@e3  link  "Issues"` | `### issues-tab` |
| `@e5  link  "New issue"` | `### new-issue-btn` |

For each interactive element you see in the snapshot:
1. Note the `@eN` ref and label
2. Get the stable selector from the DOM (use `agent-browser screenshot --annotate` to see numbered overlay)
3. Write the w2s element entry with both the `@eN` label and the selector

### Step 5 — Write workflows using agent-browser commands

Workflows in the w2s skill reference w2s element refs. At runtime, agent-browser maps those refs to its current `@eN` refs.

See [agent-browser-commands.md](./agent-browser-commands.md) for the full command reference that maps to w2s workflow actions.

---

## Running a w2s skill through agent-browser

### The lookup chain

When agent-browser executes a w2s skill, it follows this chain:

```
w2s skill (workflow: "Click `new-issue-btn`")
    ↓
w2s element inventory looks up `new-issue-btn`:
    selector: `a[href$="/issues/new"]`
    fallback: text="New issue"
    location: top-right of main column, green
    ↓
agent-browser maps selector to @eN:
    agent-browser find "a[href$='/issues/new']" --first
    → returns @e12 (or whichever ref the current snapshot has)
    ↓
agent-browser click @e12
```

### The runtime bridge

The bridge is a simple script that reads the w2s skill, finds the relevant element, and calls agent-browser. See `examples/web2skill-agent-browser/w2s-runner.sh` for the implementation.

### Quick example

```bash
# Start a session
agent-browser open https://github.com/foo/bar

# Load a w2s skill and find an element by its w2s ref
SKILL_DIR=~/.claude/skills/github.com

# Find the star button using the skill's selector
agent-browser find 'a[href$="/foo/bar"]' --first
# Returns @e5

agent-browser click @e5
# Stars the repo

agent-browser snapshot -i
# Verify: star button now says "Unstar"
```

See `examples/web2skill-agent-browser/` for a complete worked example with a full w2s skill and the runtime bridge script.

---

## Key agent-browser commands for w2s

| w2s workflow action | agent-browser command |
|---|---|
| Navigate to URL | `agent-browser open <url>` |
| Confirm on route | `agent-browser url` → verify |
| Find element by ref | `agent-browser find <selector> --first` |
| Click element | `agent-browser click <@eN>` |
| Type into field | `agent-browser type <@eN> "<text>"` |
| Wait for element | `agent-browser wait <selector>` |
| Verify state | `agent-browser snapshot -i` |
| Get current URL | `agent-browser url` |
| Screenshot with labels | `agent-browser screenshot --annotate` |
| Batch commands | `agent-browser batch --json` |

See [agent-browser-commands.md](./agent-browser-commands.md) for the full command reference.

---

## Compiling w2s skills for agent-browser specifically

To produce skills optimized for agent-browser (rather than a generic browser agent):

### Use accessibility-based selectors

Prefer selectors that align with what the accessibility tree exposes:

```markdown
### `new-issue-btn`
- type: button
- selector: `role=button[name="New issue"]`     ← agent-browser native
- fallback: `a[href$="/issues/new"]`           ← DOM fallback
- location: top-right of main column, green
- ab-ref: "@e5  button  "New issue""         ← the snapshot line
```

The `ab-ref` field records the exact agent-browser snapshot line for the element. This makes the skill self-documenting for agent-browser users.

### Write workflows as command sequences

In addition to the standard w2s prose workflows, include an `## Agent Browser Commands` section with the literal agent-browser commands:

```markdown
## Workflows

### Create a new issue

1. Confirm on route `/owner/repo/issues`
2. Click `new-issue-btn`
3. Fill in title (input labeled "Title")
4. Click "Submit new issue"

## Agent Browser Commands

### Create a new issue

agent-browser click @e5
agent-browser type @e8 "Issue title"
agent-browser type @e9 "Issue body"
agent-browser click @e12
```

This dual-format approach means the skill works with:
- Any agent that reads the prose workflow
- agent-browser directly via the command section
- Any LLM that uses the skill as context

---

## See also

- [agent-browser README](https://github.com/vercel-labs/agent-browser)
- [agent-browser skills docs](https://github.com/vercel-labs/agent-browser/tree/main/skill-data/core)
- [w2s format spec](../../w2s/format-spec.md)
- [agent-browser commands reference](./agent-browser-commands.md)
- [`examples/web2skill-agent-browser/`](../examples/web2skill-agent-browser/) — full worked example