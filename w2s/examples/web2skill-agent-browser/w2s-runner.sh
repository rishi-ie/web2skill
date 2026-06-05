#!/usr/bin/env bash
# w2s-runner.sh — runtime bridge between w2s skills and agent-browser
#
# Reads the Agent Browser Commands section from a w2s SKILL.md file
# and executes them via the agent-browser CLI.
#
# Usage:
#   ./w2s-runner.sh <skill-dir> "<goal>"
#   ./w2s-runner.sh home "Show me the home page"
#   ./w2s-runner.sh login "Log in with test@example.com / password123"
#
# Exit codes:
#   0  — workflow executed successfully
#   1  — element not found
#   2  — navigation failed
#   3  — timeout
#   4  — invalid arguments / skill file not found

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
    echo "Usage: $0 <skill-dir> <goal>"
    echo ""
    echo "  skill-dir  — path to a w2s skill directory (e.g. home, login)"
    echo "  goal       — description of what to do (matched against section headings)"
    echo ""
    echo "Examples:"
    echo "  $0 home \"Show me the home page\""
    echo "  $0 login \"Log in with test@example.com\""
    echo ""
    echo "Exit codes: 0=success, 1=element not found, 2=navigation failed, 3=timeout"
    exit 4
}

log() {
    echo "[w2s-runner] $*"
}

err() {
    echo "[w2s-runner] ERROR: $*" >&2
}

# Check that agent-browser is installed and reachable
check_agent_browser() {
    if ! command -v agent-browser &>/dev/null; then
        err "agent-browser not found. Install with: npm i -g agent-browser"
        exit 4
    fi

    # Check if browser is running (daemon should be up)
    if ! agent-browser url &>/dev/null; then
        log "No browser session. Use 'agent-browser open <url>' to start one first."
        log "Or add an 'agent-browser open <url>' command as the first step in your workflow."
    fi
}

# Extract a named workflow from a SKILL.md file
# Arguments: <file> <workflow-name>
# Output: the workflow body (Agent Browser Commands section)
extract_workflow() {
    local file="$1"
    local goal="$2"

    if [[ ! -f "$file" ]]; then
        err "Skill file not found: $file"
        return 1
    fi

    # Find the Agent Browser Commands section
    local in_ab_section=false
    local in_workflow=false
    local workflow_name=""
    local output=""

    while IFS= read -r line; do
        # Detect start of Agent Browser Commands section
        if [[ "$line" =~ ^##\ Agent\ Browser\ Commands ]]; then
            in_ab_section=true
            continue
        fi

        # Exit Agent Browser Commands section on next ## heading
        if $in_ab_section && [[ "$line" =~ ^##\ ]]; then
            break
        fi

        # Inside Agent Browser Commands section
        if $in_ab_section; then
            # Detect a workflow sub-heading (### <name>)
            if [[ "$line" =~ ^###\ (.+) ]]; then
                local name="${BASH_REMATCH[1]}"
                # Match against goal (fuzzy — lowercase, partial match)
                local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
                local goal_lower=$(echo "$goal" | tr '[:upper:]' '[:lower:]')

                # Check if goal matches this workflow name
                if [[ "$name_lower" == *"$goal_lower"* ]] || \
                   [[ "$goal_lower" == *"$name_lower"* ]]; then
                    in_workflow=true
                    workflow_name="$name"
                    output=""
                else
                    in_workflow=false
                fi
                continue
            fi

            # Collect lines for the current workflow
            if $in_workflow; then
                # Skip empty lines at start
                if [[ -z "$output" && -z "$line" ]]; then
                    continue
                fi
                output+="$line"$'\n'
            fi
        fi
    done < "$file"

    # Trim trailing newlines
    output="${output%$'\n'}"
    echo "$output"
}

# Parse a code block from markdown (triple backtick) into executable lines
parse_code_block() {
    local input="$1"
    local in_block=false
    local lines=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^``` ]]; then
            if $in_block; then
                # End of block
                break
            else
                # Start of block
                in_block=true
                continue
            fi
        fi
        if $in_block; then
            # Skip the langauge tag on first line (e.g. ```bash)
            if [[ "$line" =~ ^``` ]]; then
                continue
            fi
            lines+="$line"$'\n'
        fi
    done <<< "$input"

    lines="${lines%$'\n'}"
    echo "$lines"
}

# Execute a single agent-browser command, handle errors
run_command() {
    local cmd="$1"
    local description="${2:-}"

    if [[ -n "$description" ]]; then
        log "$description"
    fi

    # Log the command (trim leading whitespace from multiline)
    local cmd_display=$(echo "$cmd" | sed 's/^[[:space:]]*//' | head -1)
    log "  $ $cmd_display"

    # Execute and capture exit code
    local output
    local exit_code=0

    # Handle multi-line commands (concatenate with &&)
    IFS=$'\n' read -rd '' -a CMD_LINES <<< "$cmd" || true
    for line in "${CMD_LINES[@]}"; do
        line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/^agent-browser[[:space:]]*//')
        if [[ -z "$line" ]]; then
            continue
        fi

        output=$(agent-browser $line 2>&1) || exit_code=$?

        if [[ $exit_code -ne 0 ]]; then
            err "Command failed (exit $exit_code): agent-browser $line"
            err "Output: $output"
            return $exit_code
        fi
    done

    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
    # Check arguments
    if [[ $# -lt 2 ]]; then
        usage
    fi

    local skill_dir="$1"
    local goal="$2"

    # Resolve skill_dir (relative to current dir or absolute)
    if [[ ! -d "$skill_dir" ]]; then
        # Try as absolute path
        if [[ ! -d "$skill_dir" ]]; then
            err "Skill directory not found: $skill_dir"
            exit 4
        fi
    fi

    # Find the SKILL.md in the skill directory
    # If the argument is a filename (e.g. "home"), append .md
    local skill_file="$skill_dir"
    if [[ ! -f "$skill_file" ]]; then
        if [[ -f "$skill_dir.md" ]]; then
            skill_file="$skill_dir.md"
        elif [[ -f "$skill_dir/home.md" ]]; then
            skill_file="$skill_dir/home.md"
        elif [[ -f "$skill_dir/login.md" ]]; then
            skill_file="$skill_dir/login.md"
        else
            # Search for a .md file matching the goal
            local match=""
            for f in "$skill_dir"/*.md; do
                if [[ -f "$f" ]]; then
                    local basename=$(basename "$f" .md)
                    if [[ "$basename" == "$skill_dir" ]] || \
                       [[ "$(echo $basename | tr '[:upper:]' '[:lower:]')" == "$(echo $goal | tr '[:upper:]' '[:lower:]')" ]]; then
                        match="$f"
                        break
                    fi
                fi
            done
            if [[ -n "$match" ]]; then
                skill_file="$match"
            fi
        fi
    fi

    if [[ ! -f "$skill_file" ]]; then
        err "No SKILL.md found in: $skill_dir"
        err "Tried: $skill_dir/*.md, $skill_dir.md, $skill_dir/<goal>.md"
        exit 4
    fi

    log "Using skill: $skill_file"
    log "Goal: $goal"
    echo ""

    # Check agent-browser is available
    check_agent_browser

    # Extract the matching workflow
    local raw_workflow
    raw_workflow=$(extract_workflow "$skill_file" "$goal") || {
        err "Failed to extract workflow for: $goal"
        exit 4
    }

    if [[ -z "$raw_workflow" ]]; then
        err "No workflow found matching: $goal"
        err "Check the 'Agent Browser Commands' section in $skill_file"
        echo ""
        echo "Available workflows in this skill:"
        grep -n "^### " "$skill_file" || true
        exit 4
    fi

    # Parse the code block
    local commands
    commands=$(parse_code_block "$raw_workflow")

    if [[ -z "$commands" ]]; then
        err "No executable commands found in workflow: $goal"
        exit 4
    fi

    # Execute each command (lines starting with agent-browser)
    local exit_code=0
    local line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^# ]] && continue

        # Strip leading/trailing whitespace
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Skip if empty after trimming
        [[ -z "$line" ]] && continue

        # Execute
        run_command "$line" "Step $line_num:"
        exit_code=$?

        if [[ $exit_code -ne 0 ]]; then
            err "Workflow failed at step $line_num (exit $exit_code)"
            err "Command: $line"
            echo ""
            log "Taking screenshot for debugging..."
            agent-browser screenshot --path "w2s-failure-$(date +%s).png" 2>/dev/null || true
            exit $exit_code
        fi

    done <<< "$commands"

    echo ""
    log "Workflow completed successfully (exit 0)"
    exit 0
}

main "$@"