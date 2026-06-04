---
name: trail-login
description: |
  The Trail login page. Email and password form. On success,
  redirects to the ?next= URL or /home.
match:
  - /^https:\/\/app\.trail\.dev\/login(\?.*)?$/
requires:
  - trail
---

# Trail — Login Page

## Page architecture

- **No top bar, no left rail** (public page)
- **Centered card (400px wide):**
  - Trail logo at the top
  - Heading: "Log in to Trail"
  - Email input
  - Password input
  - "Log in" submit button
  - "Forgot password?" link
  - "Don't have an account? Sign up" link
- **Background:** solid dark color, no images

## Element inventory

### `email-input`

- **type:** input
- **selector:** `input[name="email"]`
- **fallback:** `input[type="email"]` in the login card
- **location:** first field, below the heading

### `password-input`

- **type:** input
- **selector:** `input[name="password"]`
- **fallback:** `input[type="password"]` in the login card
- **location:** second field, below email

### `submit-btn`

- **type:** button
- **selector:** `button[type="submit"]`
- **fallback:** `button:has-text("Log in")` in the login card
- **location:** below the password field, full-width, primary
  color

### `forgot-password-link`

- **type:** link
- **selector:** `a[href="/forgot-password"]`
- **fallback:** `a:has-text("Forgot password?")` in the login
  card
- **location:** right-aligned, below the submit button

### `signup-link`

- **type:** link
- **selector:** `a[href="/signup"]`
- **fallback:** `a:has-text("Sign up")` in the login card
- **location:** below the submit button, centered

## Workflows

### Log in with email and password

1. Confirm on route `/login` (with optional `?next=<url>`)
2. Type the user's email into `email-input`
3. Type the user's password into `password-input`
4. Click `submit-btn`
5. Verify: URL changes to the `?next` value, or `/home` if no
   `?next` is set
6. If credentials are wrong, an inline error appears above the
   form: "Invalid email or password" — report to the user, do
   not retry automatically
7. If the form is in a "submitting" state (button shows spinner),
   wait for it to complete before reading state

### Reset password

1. Confirm on route `/login`
2. Click `forgot-password-link`
3. Verify: URL changes to `/forgot-password` (out of scope — the
   user must complete the reset manually)

### Navigate to signup

1. Confirm on route `/login`
2. Click `signup-link`
3. Verify: URL changes to `/signup`

## Edge cases

- **Rate limiting:** after 5 failed attempts in 10 minutes, the
  form is disabled with "Too many attempts. Try again in N
  minutes." Stop and report.
- **Email not verified:** if the user's email is not verified,
  login succeeds but the next page shows a banner: "Please
  verify your email — check your inbox." The agent should
  report this and stop.
- **Account locked:** after 20 failed attempts, the account is
  locked. Login shows "Account locked. Contact support." Stop
  and report.
- **SSO option:** some enterprise accounts have a "Log in with
  SSO" button above the email field. If the user is on SSO, they
  must click that button instead. The agent should ask the user
  if they are unsure.
