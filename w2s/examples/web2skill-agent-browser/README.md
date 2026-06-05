# Example: w2s skill with agent-browser integration

A worked example of a w2s skill that is optimized for execution through
agent-browser. Shows the dual-format approach: standard w2s prose for
general agents, plus agent-browser command sequences for direct execution.

The example uses a fictional project management tool ("Harvest Grove") that
is similar to the simple-static-site example but with agent-browser
commands embedded in the workflows.

---

## What's in this folder

```
w2s/examples/web2skill-agent-browser/
├── README.md                    ← this file
├── overview.md                  ← site map (same as simple-static-site)
├── home.md                     ← homepage skill with agent-browser commands
├── login.md                    ← login skill with agent-browser commands
├── w2s-runner.sh               ← the runtime bridge script
└── skill-commands.md            ← extracted agent-browser command sequences
```

---

## The dual-format approach

Each `SKILL.md` in this example has:

1. **Standard w2s section** (prose workflows) — for agents that read
   natural language
2. **Agent Browser Commands section** — literal `agent-browser`
   commands for direct execution

```markdown
## Workflows

### Log in

1. Confirm on route `/login`
2. Type the user's email into `email-input`
3. Type the password into `password-input`
4. Click `submit-btn`
5. Verify: URL changes to `/home`

## Agent Browser Commands

### Log in

agent-browser open https://harvestgrove.com/login
agent-browser type @e3 "user@example.com"
agent-browser type @e4 "password123"
agent-browser click @e5
agent-browser wait --selector "#dashboard"
agent-browser url
# Should be https://harvestgrove.com/home
```

The second section is what `w2s-runner.sh` reads and executes.

---

## The runtime bridge

`w2s-runner.sh` is the glue between a w2s skill and agent-browser.
It:

1. Takes a skill directory and a goal (the task to perform)
2. Finds the relevant SKILL.md file (matching the current URL)
3. Reads the **Agent Browser Commands** section
4. Executes each command via agent-browser
5. Reports success or failure

Usage:

```bash
# Set up
chmod +x w2s-runner.sh
SKILLS_DIR=~/.claude/skills/harvestgrove.com
SKILL_DIR="$SKILLS_DIR/home"

# Run a task
./w2s-runner.sh "$SKILL_DIR" "Navigate to the home page"
./w2s-runner.sh "$SKILL_DIR" "Log in and go to home"
```

The script exits with the same codes as agent-browser:
- `0` = success
- `1` = element not found
- `2` = navigation failed
- `3` = timeout

---

## What makes this agent-browser optimized

1. **Element refs are mapped to @eN.** The skill records which @eN each
   element is in the snapshot. agent-browser uses @eN directly.
2. **Batch commands.** Multi-step workflows are sent as JSON arrays
   to `agent-browser batch --json` for efficiency.
3. **Session persistence.** The runner saves the session after auth
   (`agent-browser session save harvestgrove`) so subsequent runs
   don't need to log in again.
4. **Snapshot-first verification.** Every step that changes the page
   is followed by a `snapshot -i` to verify state.
5. **Fallback selectors.** If an @eN fails, the script falls back to
   CSS selectors via `agent-browser find`.

---

## Trying it out

1. Install agent-browser:
   ```bash
   npm i -g agent-browser
   agent-browser install
   ```

2. Start a session:
   ```bash
   agent-browser open https://harvestgrove.com
   ```

3. Run a workflow:
   ```bash
   cd w2s/examples/web2skill-agent-browser
   ./w2s-runner.sh home "Show me the home page"
   ```

4. Run the login workflow:
   ```bash
   ./w2s-runner.sh login "Log in with test@example.com / password123"
   ```

The runner will execute the agent-browser commands and report the result.

---

## Adapting for real sites

For a real site, the process is:

1. **Compile** using agent-browser's snapshot to record elements:
   ```bash
   agent-browser open https://real-site.com
   agent-browser snapshot -i
   # Note the @eN for each element
   ```

2. **Author** the skill with both prose and agent-browser commands:
   - Record @eN refs in the element inventory
   - Write workflows in prose
   - Write the same workflows as agent-browser command sequences

3. **Run** using `w2s-runner.sh`:
   ```bash
   ./w2s-runner.sh <skill-dir> "<goal>"
   ```

The `w2s-runner.sh` is generic — it works with any w2s skill that has
an **Agent Browser Commands** section. The section is just markdown
under an `## Agent Browser Commands` heading containing indented
bash-style commands prefixed with `agent-browser`.

See `home.md` and `login.md` for the full skill format with embedded
agent-browser commands. See `w2s-runner.sh` for the runtime implementation.