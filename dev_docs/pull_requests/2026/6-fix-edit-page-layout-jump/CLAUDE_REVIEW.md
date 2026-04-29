# PR #6 Review — Fix leaf editor + post edit page resize jump

**Reviewer:** Claude
**Date:** 2026-04-29
**Status:** Already merged (commit `08f2baa`); review is post-hoc
**Verdict:** Approve, with one runtime bug found in adjacent code (fixed in follow-up)

---

## Summary

Two unrelated changes bundled into one PR:

1. **Doc string update** in `lib/phoenix_kit_posts.ex:7` — renames `PhoenixKit.Modules.Comments` → `PhoenixKitComments`.
2. **Layout fix** in `lib/phoenix_kit_posts/web/edit.html.heex` — replaces the flex-based 2:1 column layout with CSS grid (`grid-cols-3` + `col-span-2`) to stop the sidebar collapsing once the leaf editor mounts.

The commit trail (`aa5c161` → `0ea5ee5` → `15ecc47` → `4e5dd63` → `e1edf8a` → `c3650f3` → `8dff63b` → `fed915b` → `89b6b25`) shows the fix was iterated through several wrong attempts before landing on grid + `min-w-0` + `overflow-hidden`.

---

## What Works Well

1. **Real root-cause fix.** Flex's `flex-[2] / flex-1` ratio breaks when one child has a large intrinsic min-content width (the rich editor). Switching to grid is the correct fix — grid tracks are sized from the container, not from children's intrinsic widths, so the 2:1 split is honored regardless of editor contents.

2. **Unusually good inline comments.** The `<%!-- … --%>` block at `edit.html.heex:12-17` and `:20-21` explains *why* (flex can't honor the ratio under intrinsic min-content) rather than what — exactly the kind of comment that earns its keep. Future readers won't be tempted to "simplify" it back to flex.

3. **`min-w-0` on both columns** is the right belt-and-suspenders for grid items containing potentially overflowing content (CodeMirror/leaf editors).

4. **Tiny diff** (12/4) for a behaviorally significant fix.

---

## Issues and Observations

### 1. Namespace inconsistency revealed a runtime bug — FIXED

The doc rename in `lib/phoenix_kit_posts.ex:7` aligns with the actual call site at `lib/phoenix_kit_posts/web/details.ex:56` (`PhoenixKitComments.enabled?()`). But several other files still referenced the old `PhoenixKit.Modules.Comments` namespace:

- `lib/phoenix_kit_posts/web/details.html.heex:221` — `module={PhoenixKit.Modules.Comments.Web.CommentsComponent}` in a `<.live_component>` call. **This is a real runtime bug, not a stale doc.**
- `lib/phoenix_kit_posts/schemas/post_comment.ex:6` — deprecation note pointing at `PhoenixKit.Modules.Comments.Comment`
- `lib/phoenix_kit_posts/schemas/comment_like.ex:5` — deprecation note pointing at `PhoenixKit.Modules.Comments.CommentLike`
- `lib/phoenix_kit_posts/schemas/comment_dislike.ex:5` — deprecation note pointing at `PhoenixKit.Modules.Comments.CommentDislike`

Verification: the `phoenix_kit_comments` dep (`mix.exs`, `~> 0.1`) only exports modules under `PhoenixKitComments.*`. `PhoenixKit.Modules.Comments.Web.CommentsComponent` does not exist. When a post detail page renders with comments enabled, the `live_component` call would crash with `UndefinedFunctionError`.

**Resolution (this session):**
- Fixed `details.html.heex:221` → `PhoenixKitComments.Web.CommentsComponent` (real bug fix).
- Updated three schema docstrings to point at `PhoenixKitComments.{Comment,CommentLike,CommentDislike}` (doc consistency).
- Verified with `mix compile --warnings-as-errors` — clean.

### 2. `overflow-hidden` on the content column is risky — NOT YET ADDRESSED

`edit.html.heex:22` adds `overflow-hidden` to the left column. With `min-w-0` already present, this is mostly defensive, but it will silently clip anything that legitimately needs to escape the column box — focus rings on inputs near the edge, dropdown menus, tooltip portals, popovers from form components.

**Recommendation:** verify in a browser that no popover/menu inside the form (date picker, tag autocomplete, status dropdown, etc.) gets clipped at narrow `lg:` widths. If anything does, downgrade to `overflow-x-hidden` so vertical popovers still escape.

This requires a running dev server / browser, so was not addressed in this session.

### 3. Two unrelated changes in one PR (style)

The doc rename and the layout fix are independent and the PR title only mentions the layout. Harmless given the size, but makes `git blame` and revert-by-feature slightly noisier. Splitting would have been cleaner.

### 4. No test coverage (style, low priority)

Layout regressions like this are hard to assert in unit tests, but a quick LiveView render test on `edit.html.heex` confirming the wrapper carries `grid-cols-3` would lock the behavior and catch a future "let me clean this up" revert.

A render test on `details.html.heex` rendering with `comments_enabled: true` would have caught issue #1 above before merge.

---

## Risk Assessment

- **Correctness (PR as merged):** medium — the layout fix itself is sound, but the bundled doc rename pointed at a namespace that the live `details.html.heex` was also using incorrectly. Fixed in follow-up commit.
- **Performance:** none — pure CSS class swap.
- **Security:** none.
- **Regression surface:** the `overflow-hidden` on the content column is the only piece worth eyes-on in a browser; everything else is mechanical.

---

## Follow-up Changes Applied (post-merge)

| File | Change |
|------|--------|
| `lib/phoenix_kit_posts/web/details.html.heex:221` | `PhoenixKit.Modules.Comments.Web.CommentsComponent` → `PhoenixKitComments.Web.CommentsComponent` (runtime bug fix) |
| `lib/phoenix_kit_posts/schemas/post_comment.ex:6` | Updated deprecation pointer to `PhoenixKitComments.Comment` |
| `lib/phoenix_kit_posts/schemas/comment_like.ex:5` | Updated deprecation pointer to `PhoenixKitComments.CommentLike` |
| `lib/phoenix_kit_posts/schemas/comment_dislike.ex:5` | Updated deprecation pointer to `PhoenixKitComments.CommentDislike` |

Verified: `mix compile --warnings-as-errors` succeeds.

---

## Remaining Items (not addressed)

1. Audit `overflow-hidden` on `edit.html.heex:22` against form popovers/dropdowns in a browser; consider downgrading to `overflow-x-hidden` if anything is clipped.
2. Add LiveView render tests for both `edit.html.heex` (lock the grid layout) and `details.html.heex` with `comments_enabled: true` (would have caught the namespace bug).

---

## Verdict

Solid layout fix with strong inline rationale — the commit trail showing the author actually understood why earlier attempts didn't work is worth more than the diff size suggests. Reviewing the bundled doc rename surfaced an unrelated runtime bug in `details.html.heex` referencing a non-existent module, now fixed.
