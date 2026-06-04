# distillation.md

How to turn a live web page into a compact, token-efficient
representation suitable for the compiler. Load this file before
distilling any URL.

The goal: from a page that may be 50K+ tokens of raw HTML, produce a
distilled view under 5,000 tokens that still contains everything an
agent needs to navigate the page later.

## The principle

Distillation is lossy by design. We are NOT trying to preserve the
page. We are trying to preserve the parts of the page an agent needs
to (a) find elements, (b) decide what to click, and (c) recognize
state.

The agent will use the output of distillation to write a `SKILL.md`.
That `SKILL.md` is what other agents will read at runtime. So the
distilled view only needs to support the writing of the skill — it
does not need to be readable on its own.

## What to keep

### Interactive elements

Every interactive element gets recorded. By "interactive," we mean
elements the user (or agent) can act on:

- Buttons (`<button>`, `role=button`)
- Links (`<a>` with meaningful `href`)
- Form fields (`<input>`, `<textarea>`, `<select>`)
- Checkboxes, radios, switches
- Tabs, accordions, disclosure widgets
- Dropdown menu triggers
- Sliders, draggable items
- File upload zones
- Search inputs (even if just a plain `<input type="search">`)

For each, record:

- **`ref`** — a stable, descriptive name (kebab-case). The agent
  uses this in the skill. Example: `new-issue-btn`,
  `search-input`, `filter-open-closed`.
- **`type`** — button, link, input, etc.
- **`label`** — what the element says. Prefer the visible text
  label; fall back to `aria-label`; fall back to
  `placeholder`/`title`/`value`.
- **`role`** — the accessibility role, if non-obvious
  (`button`, `link`, `menuitem`, `tab`, `option`, etc.)
- **`selector`** — the most stable CSS selector you can find (see
  Selector quality below).
- **`location`** — short prose describing where on the page
  ("top-right of main column, green button").

### Layout regions

The high-level structure of the page: header, sub-header, left
rail, main column, right rail, footer, modal, banner. For each
region, a one-sentence description of what is in it. Reference
elements by `ref` where appropriate.

### Visible text content

The text that an agent would need to recognize the page state:
headings, section titles, status messages, error messages, empty
state copy. Do NOT preserve paragraphs of body text, marketing
copy, legal text, or anything that is not load-bearing for
navigation.

### Modals, banners, and overlays

Anything that is layered on top of the page and partially obscures
it: cookie banners, "sign up for our newsletter" modals, "your
trial ends in N days" banners, "install our app" prompts, etc. For
each, record: what it says, where it is, and how to dismiss it
(which element ref).

### Form structures

For forms, record every field and its label, even if all fields are
just text inputs. The skill writer needs to be able to write
workflows like "fill in the email field, fill in the password
field, click submit."

### Repeated patterns

If a list of items appears (issue rows, search results, file tree
nodes), record ONE element ref for the row template and one for
each significant child. Do not enumerate every row.

Example:

```markdown
### `issue-row`

- **type:** repeatable
- **selector:** `[data-testid="issue-row"]`
- **location:** each row in main column
- **contains:** `issue-title`, `issue-number`, `issue-labels`,
  `issue-author`, `issue-timestamp`
```

This is the single biggest token saver on list-heavy pages.

## What to ignore

- **Scripts, styles, JSON-LD, embeds.** All `<script>`, `<style>`,
  `<link rel="stylesheet">`, `<noscript>`, `<iframe>` (unless
  visibly interactive and important), `<object>`, `<embed>`.
- **Hidden elements.** Anything with `display: none`,
  `visibility: hidden`, `hidden` attribute, `aria-hidden="true"`,
  `tabindex="-1"` and not currently focused, or zero size
  (`width: 0` and `height: 0`).
- **Decorative images and SVGs.** `<img>` that is purely visual
  (logos, illustrations, avatars shown as decoration). KEEP
  `<img>` if it is the only representation of meaningful content
  (a product photo, a user-uploaded screenshot, etc.).
- **Ads and trackers.** Anything in an iframe, anything with
  classes/ids suggesting ads (`ad-`, `ads-`, `analytics-`,
  `tracking-`, `pixel-`), anything from a third-party domain.
- **Marketing chrome.** Footer links to "About us," "Careers,"
  "Press," "Terms of service," "Privacy policy" — UNLESS those are
  the actual routes the agent needs to navigate to.
- **Decorative repetition.** A long list of identical footer
  links, a sidebar of related-content links, a "you might also
  like" carousel. One representative example is enough; the rest
  is noise.
- **Empty containers.** `<div>`s with no content, no children of
  interest, and no semantic purpose.
- **Form helpers.** Hidden inputs (`<input type="hidden">`),
  CSRF tokens, tracking fields.
- **Repeated identical structures.** If a list has 50 items, do
  not list all 50. List the structure once, with `repeatable`
  semantics.

## Selector quality

The selectors you record determine whether the skill will keep
working when the site is redesigned. Use this priority order:

1. **`[data-testid="<name>"]`** — best. Designed to be stable.
2. **`#<stable-id>`** — good. The element has a real, semantic ID.
3. **`[aria-label="<exact>"]`** — good. Semantic and stable.
4. **`[name="<form-field-name>"]`** — good for form fields.
5. **`[role="<role>"][aria-label="<exact>"]`** — good. The
   combination is more specific than either alone.
6. **Semantic CSS:** `nav a[href="/pricing"]`,
   `form input[type="email"]` — acceptable. Tied to structure.
7. **Text-based:** `button:has-text("Sign in")`,
   `a:has-text("Pricing")` — last resort. Text can change with
   copy updates.
8. **FORBIDDEN:** auto-generated class hashes
   (`.css-1a2b3c`, `.jsx-abc123`), positional selectors
   (`div > div:nth-child(2) > a`), and deeply nested descendant
   chains with no semantic anchor. If the only selector you can
   produce is one of these, do not record the element.

When you record a `selector` field, also record a `fallback`
selector one level down the priority list. The agent will try the
primary first, then the fallback.

## Tool-specific guidance

Different agents have different browser tools. Adapt the
distillation method to your tool, but the OUTPUT FORMAT must match
what `format-spec.md` expects.

### If you have a real browser (Playwright, Puppeteer, browser-use)

- Open the page
- Wait for `networkidle` (no requests in flight for 500ms)
- Use the accessibility tree (`page.accessibility.snapshot()` in
  Playwright) as your starting point — it gives you roles, names,
  and properties for free
- Cross-reference with the live DOM for selectors and locations
- Take a screenshot for layout reference (don't put the screenshot
  in the output, just use it to write the page architecture
  section)

### If you have a "fetch and parse" tool (curl, web fetch)

- Fetch the HTML
- Strip `<script>`, `<style>`, `<noscript>`, hidden elements
- For each remaining element, extract label, role, attributes that
  would be a stable selector
- You will NOT get layout information (positions, sidebars) — say
  so in the page architecture section ("layout inferred from HTML
  structure, not from rendering")
- You will NOT see modals or dynamic content — flag this in the
  edge cases section

### If you have computer use (vision-based browser)

- Open the page
- Look at it
- For each visible interactive element, describe what you see: the
  label, its position, its appearance
- This is the most expensive option in tokens but the most
  reliable for SPAs that don't expose semantic HTML
- The selectors you record will be weaker (often text-based only)

## Output format

The distilled view is your working scratchpad — it does not get
saved as a file. It is the structured notes you take while
inspecting the page, and the source material you use to write the
`SKILL.md`. Organize it in roughly the same structure as the final
skill (architecture, elements, workflows, edge cases) but at lower
fidelity.

## Anti-patterns

- Do not record every link in a footer. Record the footer as a
  region, mention "30+ footer links present," and move on.
- Do not record every CSS class. Classes are implementation
  detail; refs and roles are what matter.
- Do not describe the page in human prose ("a beautiful clean
  layout with a blue header"). That belongs in a marketing
  brochure, not a skill.
- Do not record decorative content (avatar images, brand logos)
  as elements. They are not interactive.
- Do not record dynamic content that you only saw once and that
  will not be present on the next load (toast notifications,
  "welcome back" modals). Mention them in edge cases instead.