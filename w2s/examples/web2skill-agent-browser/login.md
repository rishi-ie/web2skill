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
- **ab-ref:** "@e3  form  "Log in to your account""

### `email-input`

- **type:** input
- **selector:** `[data-testid="login-email"]`
- **fallback:** `input[type="email"]` inside `login-form`
- **location:** first field in the form
- **ab-ref:** "@e4  textbox  "Email""

### `password-input`

- **type:** input
- **selector:** `[data-testid="login-password"]`
- **fallback:** `input[type="password"]` inside `login-form`
- **location:** second field in the form, below email
- **ab-ref:** "@e5  textbox  "Password""

### `submit-btn`

- **type:** button (submit)
- **selector:** `[data-testid="login-submit"]`
- **fallback:** `button[type="submit"]` inside `login-form`
- **location:** below the password field, full-width
- **ab-ref:** "@e6  button  "Log in""

### `forgot-password-link`

- **type:** link
- **selector:** `[data-testid="login-forgot-password"]`
- **fallback:** `a:has-text("Forgot password?")` inside `login-form`
- **location:** right-aligned, below the password field
- **ab-ref:** "@e7  link  "Forgot password?""

### `signup-link`

- **type:** link
- **selector:** `[data-testid="login-to-signup"]`
- **fallback:** `a:has-text("Sign up")` inside `login-form`
- **location:** below the submit button, small text
- **ab-ref:** "@e8  link  "Sign up""

## Workflows

### Log in with email and password

1. Confirm on route `/login`
2. Type the user's email into `email-input`
3. Type the user's password into `password-input`
4. Click `submit-btn`
5. Verify: page redirects to `app.harvestgrove.com` (OUT OF SCOPE for this skill)
6. If credentials are wrong, the page reloads with an error "Invalid email or password" above the form — report to the user, do not retry

### Navigate to signup from login

1. Confirm on route `/login`
2. Click `signup-link`
3. Verify: URL changes to `/signup`

### Reset password

1. Confirm on route `/login`
2. Click `forgot-password-link`
3. Verify: URL changes to `/forgot-password` (out of scope — user completes manually)

## Agent Browser Commands

### Log in with email and password

```bash
agent-browser open https://harvestgrove.com/login
agent-browser snapshot -i

# Type email
agent-browser type @e4 "user@example.com"

# Type password
agent-browser type @e5 "password123"

# Submit
agent-browser click @e6

# Wait for redirect — either app.harvestgrove.com or error message
# Check URL after 3 seconds
agent-browser url
# If https://app.harvestgrove.com: success
# If still on /login: check for error
agent-browser snapshot -i
# If @e9 contains "Invalid email or password": credentials wrong
```

### Navigate to signup from login

```bash
agent-browser open https://harvestgrove.com/login
agent-browser snapshot -i
agent-browser click @e8
agent-browser wait --selector "#signup-form"
agent-browser url
# Should be https://harvestgrove.com/signup
```

## Edge cases

- **Validation errors:** empty email → "@e4 label shows 'Email is required'"; empty password → "@e5 label shows 'Password is required'"
- **Wrong credentials:** error "Invalid email or password" appears above the form. The page does NOT distinguish between "no such user" and "wrong password."
- **Rate limiting:** after 5 failed attempts, form shows "Too many attempts. Please try again later." Stop and report.
- **Redirect after login:** if URL has `?redirect=<path>`, user goes there after login.