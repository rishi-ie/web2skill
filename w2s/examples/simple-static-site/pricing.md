---
name: harvestgrove-pricing
description: |
  The Harvest Grove pricing page. Two plan cards (Free and Pro)
  with feature lists, plus a comparison table below.
match:
  - /^https:\/\/harvestgrove\.com\/pricing\/?$/
requires:
  - harvestgrove
---

# Harvest Grove — Pricing Page

## Page architecture

- **Header (inherited from overview):** logo + nav
- **Page title:** "Simple, transparent pricing" at the top
- **Plan cards (main column, two cards side by side):**
  - **Free plan (left):** $0/month, "Get started" CTA
  - **Pro plan (right):** $12/month, "Start free trial" CTA
- **Comparison table (below the cards):** full feature list with
  check/cross marks per plan
- **FAQ section (below the table):** 4-5 collapsible questions
- **Footer (inherited from overview)**

## Element inventory

### `plan-card-free`

- **type:** container
- **selector:** `[data-testid="plan-card-free"]`
- **location:** left plan card
- **contains:** `plan-free-name`, `plan-free-price`,
  `plan-free-features`, `plan-free-cta`

### `plan-card-pro`

- **type:** container
- **selector:** `[data-testid="plan-card-pro"]`
- **location:** right plan card (highlighted, recommended)
- **contains:** `plan-pro-name`, `plan-pro-price`,
  `plan-pro-features`, `plan-pro-cta`

### `plan-free-cta`

- **type:** link
- **selector:** `[data-testid="plan-free-cta"]`
- **fallback:** `a:has-text("Get started")` inside `plan-card-free`
- **location:** bottom of the Free plan card

### `plan-pro-cta`

- **type:** link
- **selector:** `[data-testid="plan-pro-cta"]`
- **fallback:** `a:has-text("Start free trial")` inside
  `plan-card-pro`
- **location:** bottom of the Pro plan card

### `comparison-table`

- **type:** container
- **selector:** `[data-testid="comparison-table"]`
- **location:** below the plan cards
- **contains:** rows for each feature with check/cross per column

### `faq-item` (repeatable)

- **type:** repeatable
- **selector:** `[data-testid="faq-item"]`
- **location:** FAQ section
- **contains:** `faq-question`, `faq-answer`

## Workflows

### Read the Pro plan features

1. Confirm on route `/pricing`
2. Read `plan-pro-name`, `plan-pro-price`, and the items in
   `plan-pro-features` for the bullet list
3. If you need the detailed comparison, read the relevant rows
   in `comparison-table` (the "Pro" column)

### Start a Pro trial

1. Confirm on route `/pricing`
2. Click `plan-pro-cta`
3. Verify: URL changes to `/signup?plan=pro`, page shows the
   signup form pre-filled with plan=Pro

### Start on the Free plan

1. Confirm on route `/pricing`
2. Click `plan-free-cta`
3. Verify: URL changes to `/signup?plan=free`, page shows the
   signup form pre-filled with plan=Free

### Open an FAQ

1. Confirm on route `/pricing`
2. Click the relevant `faq-item` (specifically `faq-question`)
3. Verify: the `faq-answer` for that item becomes visible (the
   item expands)

## Edge cases

- **Plan not specified in URL:** if the user lands on
  `/signup` without `?plan=...`, the form defaults to Free. The
  signup skill should handle this.
