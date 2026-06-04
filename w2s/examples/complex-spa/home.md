---
name: trail-home
description: |
  The Trail dashboard. Personalized greeting, recent activity
  feed, and quick links to teams. Default landing page after
  login.
match:
  - /^https:\/\/app\.trail\.dev\/home\/?$/
requires:
  - trail
---

# Trail — Dashboard (Home)

## Page architecture

- **Top bar (inherited from overview):** logo, team switcher,
  global search, inbox icon, notifications icon, avatar
- **Left rail (inherited from overview):** team list
- **Main column:**
  - Greeting header: "Good morning, <first name>" (changes
    based on time of day)
  - "Your teams" section: cards for each team the user belongs
    to, showing open issue count
  - "Recent activity" section: list of recent events (issues
    created, status changed, comments added), most recent first

## Element inventory

### `greeting`

- **type:** static text
- **selector:** `[data-testid="greeting"]`
- **location:** top of main column

### `teams-section`

- **type:** container
- **selector:** `[data-testid="teams-section"]`
- **location:** below the greeting
- **contains:** `team-card` (repeatable, one per team)

### `team-card` (repeatable)

- **type:** repeatable
- **selector:** `[data-testid="team-card"]`
- **location:** grid of cards, 2-3 per row depending on
  viewport
- **contains:** `team-card-name` (link to the team view),
  `team-card-issue-count`, `team-card-avatar`

### `activity-section`

- **type:** container
- **selector:** `[data-testid="activity-section"]`
- **location:** below `teams-section`
- **contains:** `activity-item` (repeatable)

### `activity-item` (repeatable)

- **type:** repeatable
- **selector:** `[data-testid="activity-item"]`
- **location:** list in `activity-section`
- **contains:** `activity-icon`, `activity-text`,
  `activity-timestamp`, `activity-target-link` (when
  applicable)

## Workflows

### Open a team

1. Confirm on route `/home`
2. Click the `team-card-name` link for the desired team in
   `teams-section`
3. Verify: URL changes to `/<team>`, team view loads

### Read recent activity

1. Confirm on route `/home`
2. Scroll to `activity-section` (may need to scroll the main
   column if many teams are shown)
3. Read `activity-item` rows top-to-bottom; each shows
   `<user> <action> <target> <timestamp>`

### Open an issue from recent activity

1. Confirm on route `/home`
2. Find the `activity-item` for the desired issue
3. Click `activity-target-link` within that item
4. Verify: URL changes to `/<team>/issue/<id>`, issue view
   loads (load `issue.md` skill)

## Edge cases

- **Welcome modal:** the first time a user lands on `/home`
  after signup, a welcome modal appears with onboarding steps.
  Dismiss with the "X" button in the modal header (the modal
  has no test ID but is dismissible with the Escape key).
- **No teams yet:** if the user has been removed from all
  teams, `teams-section` is empty and shows a "Create a team"
  button. Click it to start team creation (out of scope for
  this skill — requires `/settings/team/new`).
- **Empty activity:** if there is no recent activity,
  `activity-section` shows "No recent activity."
- **Loading state:** `teams-section` and `activity-section`
  each show skeleton loaders for 200-1500ms after navigation.
  Wait for real content before reading.
