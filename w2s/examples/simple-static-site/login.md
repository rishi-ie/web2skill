---
name: harvestgrove-login
description: |
  The Harvest Grove login page. Email and password form that
  authenticates and redirects to app.harvestgrove.com.
match:
  - /^https:\/\/harvestgrove\.com\/login(\?.*)?$/
requires:
  - harvestgrove
---

# Harvest Grove — Login Page

## Page architecture

- **Header (inherited from overview):** logo + nav
- **Form container (centered, ~400px wide):**
  - Heading: "Log in to your account"
  - Email field
  - Password field
  - "Log in" submit button
  - "Forgot password?" link
  - Link to "/signup" for new users
- **Footer (inherited from overview)**

## Element inventory

### `login-form`

- **type:** form
- **selector:** `[data-testid="login-form"]`
- **location:** centered in main column
- **contains:** `email-input`, `password-input`, `submit-btn`

### `email-input`

- **type:** input
- **selector:** `[data-testid="login-email"]`
- **fallback:** `input[type="email"]` inside `login-form`
- **location:** first field in the form

### `password-input`

- **type:** input
- **selector:** `[data-testid="login-password"]`
- **fallback:** `input[type="password"]` inside `login-form`
- **location:** second field in the form, below email

### `submit-btn`

- **type:** button (submit)
- **selector:** `[data-testid="login-submit"]`
- **fallback:** `button[type="submit"]` inside `login-form`
- **location:** below the password field, full-width

### `forgot-password-link`

- **type:** link
- **selector:** `[data-testid="login-forgot-password"]`
- **fallback:** `a:has-text("Forgot password?")` inside
  `login-form`
- **location:** right-aligned, below the password field

### `signup-link`

- **type:** link
- **selector:** `[data-testid="login-to-signup"]`
- **fallback:** `a:has-text("Sign up")` inside `login-form`
- **location:** below the submit button, small text

## Workflows

### Log in with email and password

1. Confirm on route `/login`
2. Type the user's email into `email-input`
3. Type the user's password into `password-input`
4. Click `submit-btn`
5. Verify: page redirects to `app.harvestgrove.com` (OUT OF
   SCOPE for this skill)
6. If credentials are wrong, the page reloads with an error
   "Invalid email or password" above the form — report to the
   user, do not retry automatically with a guessed password

### Reset password

1. Confirm on route `/login`
2. Click `forgot-password-link`
3. Verify: URL changes to `/forgot-password` (out of scope for
   this skill; the user must complete the reset manually)

### Navigate to signup from login

1. Confirm on route `/login`
2. Click `signup-link`
3. Verify: URL changes to `/signup`

## Edge cases

- **Validation errors:**
  - Empty email: error "Email is required" below `email-input`
  - Empty password: error "Password is required"
- **Wrong credentials:** error "Invalid email or password" above
  the form. The page does NOT distinguish between "no such user"
  and "wrong password" (good security practice).
- **Rate limiting:** after 5 failed attempts in 10 minutes, the
  form is disabled with "Too many attempts. Please try again
  later." Stop and report.
- **Redirect after login:** if the URL has `?redirect=<path>`,
  the user is sent to `<path>` after a successful login
  (otherwise they go to the app home).
