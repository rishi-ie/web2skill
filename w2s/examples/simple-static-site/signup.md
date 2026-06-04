---
name: harvestgrove-signup
description: |
  The Harvest Grove signup page. Email capture form that creates
  a new account and redirects to app.harvestgrove.com.
match:
  - /^https:\/\/harvestgrove\.com\/signup(\?.*)?$/
requires:
  - harvestgrove
---

# Harvest Grove — Signup Page

## Page architecture

- **Header (inherited from overview):** logo + nav
- **Form container (centered, ~400px wide):**
  - Heading: "Create your account"
  - Subheading (if `?plan=pro` or `?plan=free` in URL): shows
    selected plan ("You selected: Pro" or "You selected: Free")
  - Email field
  - Password field
  - "Create account" submit button
  - Link to "/login" for existing users
- **Footer (inherited from overview)**

## Element inventory

### `signup-form`

- **type:** form
- **selector:** `[data-testid="signup-form"]`
- **location:** centered in main column
- **contains:** `email-input`, `password-input`, `submit-btn`

### `email-input`

- **type:** input
- **selector:** `[data-testid="signup-email"]`
- **fallback:** `input[type="email"]` inside `signup-form`
- **location:** first field in the form

### `password-input`

- **type:** input
- **selector:** `[data-testid="signup-password"]`
- **fallback:** `input[type="password"]` inside `signup-form`
- **location:** second field in the form, below email

### `submit-btn`

- **type:** button (submit)
- **selector:** `[data-testid="signup-submit"]`
- **fallback:** `button[type="submit"]` inside `signup-form`
- **location:** below the password field, full-width

### `login-link`

- **type:** link
- **selector:** `[data-testid="signup-to-login"]`
- **fallback:** `a:has-text("Log in")` inside `signup-form`
- **location:** below the submit button, small text

### `plan-indicator`

- **type:** static text (only present if URL has `?plan=...`)
- **selector:** `[data-testid="signup-plan-indicator"]`
- **location:** below the heading, above the form fields

## Workflows

### Sign up with email and password

1. Confirm on route `/signup` (or `/signup?plan=...`)
2. Type the user's email into `email-input`
3. Type the desired password into `password-input`
4. Click `submit-btn`
5. Verify: page redirects to `app.harvestgrove.com/onboarding`
   (this is OUT OF SCOPE for this skill — the agent's job ends
   at "form submitted successfully")
6. If the email is already in use, the page shows an inline
   error below `email-input` reading "An account with this
   email already exists" — the agent should report this to the
   user and stop

### Navigate to login from signup

1. Confirm on route `/signup`
2. Click `login-link`
3. Verify: URL changes to `/login`

## Edge cases

- **Validation errors:**
  - Empty email: error "Email is required" below `email-input`
  - Invalid email format: error "Please enter a valid email"
  - Empty password: error "Password is required"
  - Password too short: error "Password must be at least 8
    characters"
- **Plan pre-selected via URL:** if `?plan=pro` is in the URL,
  `plan-indicator` reads "You selected: Pro" and the new account
  will be created on the Pro plan. Same for `?plan=free`.
- **Rate limiting:** after 5 failed attempts from the same IP
  in 10 minutes, the form is temporarily disabled and shows
  "Too many attempts. Please try again later." Stop and report
  to the user.
