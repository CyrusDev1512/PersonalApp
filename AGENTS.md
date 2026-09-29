# AGENTS.md — notes for AI coding agents

fbkit is a CLI (`uv run fb …`) that drives one Facebook personal/professional
profile: post, schedule, comment, list/delete own posts, insights and subscriber
snapshots (GraphQL), plus login and Messenger reading (Playwright). README.md is
the user manual; this file is what an agent must know before changing or
operating it. Every command here acts on a **real, live account** — there is no
sandbox.

## Hard rules

- **Never narrate a result you did not capture.** For every post/schedule/delete
  print the raw exit code and raw stdout. The tool is built so that "success" is
  verified against Facebook's own response (returned `post_id`, the comment edge
  node, the privacy read-back, a re-count after delete). Keep that property: a
  new command must not claim success from a click that merely "happened".
- **Rehearse with `--privacy SELF` first**, then run the real audience.
  Exception: `SUBSCRIBERS` is a different object (base_state SELF + allow-list
  id) and cannot be rehearsed with SELF; verify a real subscriber post by opening
  its URL in a cookie-less browser context — it must NOT render.
- **Never hard-code an audience id.** The subscriber allow-list id is
  per-account; the code resolves it at post time via
  `CometPrivacySelectorPickerContainerQuery` and matches on the icon name
  `supporter_exclusive` (labels are language-dependent, icons are not). If it
  cannot be resolved, abort — never fall back to a wider audience.
- **Delete-by-index always needs `--match`.** Content Library GraphQL order is
  not chronological and differs from the browser list; `post-delete` /
  `post-delete-scheduled` refuse a bare index. Published posts cannot be
  recovered.
- **Never re-post when only the comment failed.** `fb post … --comment` prints
  the rescue command (`post-list-scheduled` → `comment-scheduled <index> "…"
  --match "…"`). The post exists; re-posting creates a duplicate.
- **Rescheduling = delete + re-create.** There is no edit command. Note the
  audience and text first, re-apply the same `--privacy`, `--image`, `--comment`.
  Facebook also allows editing a *published* post to add a photo — do not tell a
  user to delete-and-repost for that.
- `profiles/<name>/` holds cookies, the E2EE PIN and subscriber snapshots
  (third-party names). It is gitignored; never read it into a transcript, never
  print its content, never commit it.
- `fb login` opens a headed browser; run it in the foreground for the user.

## Behaviour facts that shape any change

- **Content Library is the only source of truth for own posts** (published,
  scheduled, drafts): `ProdashCometV2ContentLibraryQuery` + pagination query.
  Pagination `id` must be the library page id returned by page one, not the
  `c_user`. The profile page (`/me`, `/<vanity>`) does not reliably load the
  wall — never scrape it to verify a post.
- **Deferred GraphQL responses**: some queries stream the table as later
  newline-separated chunks (`is_final:false`). `graphql_chunks()` in
  `fb_session.py` collects all of them; a "200 but empty data" symptom means a
  query is still using the single-chunk `graphql_request()`.
- **Shared-session Content-Type contamination**: `graphql_request()` leaves
  `Content-Type: application/x-www-form-urlencoded` on the requests session, so
  a multipart upload issued afterwards is sent with the wrong header (400).
  `upload_photo()` pops and restores it; any new non-form request must do the
  same. Symptom pattern: `--privacy SELF` works, `SUBSCRIBERS` fails (the
  allow-list resolution is a GraphQL call before the upload).
- **Comment timing**: commenting right after creating a post returns
  `code 1446013` ("post removed") because Facebook has not indexed it yet.
  `_create_comment()` waits 5 s and retries 3× — keep it on both the immediate
  and scheduled paths.
- **Scheduling window ≈ 30 days**; the CLI fails before submit when out of
  range. Minimum lead time 10 minutes.
- **Insights are SSR-preloaded**, not XHR: the doc ids came from
  `preloaderID/queryID` in the page HTML, so network capture will never show
  them. Buckets are US Pacific. Subscriber *count* is authoritative from the
  subscriber-list dialog query, not the insights card (the card lags).
- `post-list-published` prints times shifted +8 h (display bug); use it to
  confirm a post exists, not to check a schedule time.
- Browser-driven flows (`--composer`, `fb report`, Messenger) use zh-TW labels
  and are documented as such in README. In Content Library, "visible but not
  clickable" elements are covered by a transparent wrapper — use
  `_click_through()` (falls back to `el.click()` via evaluate).
- Multi-photo: `--image` is repeatable on the GraphQL path; `--composer` takes
  one image only. Nothing can read back a *scheduled* post's attachments — verify
  by upload log (one photoID per file) or in Content Library by eye.
- Test images must be real photos (e.g. `ffmpeg -f lavfi -i color=…` JPG); a
  tiny synthetic PNG is rejected by Facebook while the attach check still
  passes.

## Messenger reading

- Find the thread with `fb inbox --count 30` (name + thread id + E2E flag), then
  `fb read <id> --count N`. Prefer inbox → read over `fb search` (the search box
  is intercepted by an overlay). Contact names must match Messenger's displayed
  name exactly; on ambiguity the tool lists candidates instead of guessing.
- E2EE threads: `fb read` restores messages and enters the PIN automatically.
  Known gaps: `_looks_e2ee()` decides by ">15 digits", so a 15-digit E2EE thread
  is routed to the non-E2EE URL and returns 0 messages (trust the inbox E2E
  column; fix should consult inbox/contacts instead of digit count). E2EE
  `--count` is not "latest N" — above ~42 the restore window drifts into old
  history; read recent threads with `--count ≤ 42` and stitch several runs to go
  further back. The drift can start well below 42 (a thread with years of
  history drifted at `--count 30`); if the newest message looks old, retry
  with `--count 10`. E2EE image attachments are base64 `data:` URIs in
  `div[role=main] img`, not fbcdn URLs; `fb read` does not save them.
- E2EE *file* attachments (pptx, pdf, …) are `<a href="blob:…"
  download="<filename>">` — decrypted in the page, no URL to fetch from outside.
  `fb read <id> --count N --save-attachments DIR` reads each blob in the page
  and saves it (size-checked). Do not open a browser by hand for this.
- Sending files: `fb send <id> "text" --file a.pptx --file a.pdf`. Facts the
  code relies on: the composer box is the textbox's 4th ancestor (attachment
  preview = element with `aria-label` = filename, plus 「移除附件」); the
  enclosing `[role=region]` can wrap the whole conversation, so never scope
  composer checks to it. The attach button label states the size limit
  (「附加最大25 MB 的檔案」regular, 100 MB E2EE) — a regular self-thread cannot
  rehearse a >25 MB E2EE send. After attaching, page-level keyboard input no
  longer reaches the textbox; type with element-targeted calls.
- E2EE sent files (verified 2026-09-29): the sender's `a[download]` link
  appears immediately, before upload — it is NOT delivery. No Playwright
  request event fires for the upload, so do not wait on network idle.
  Delivery = the status line 「已傳送」 after the file; proof = the link is
  still there after a reload. Closing the browser earlier silently drops
  the file.

## Capturing a new mutation (how the GraphQL paths were built)

- Attach a context-level `request` listener on `/api/graphql` inside
  `create_browser_context`, run the browser flow once, diff the captured
  variables against a known payload.
- Multipart bodies are invisible to Playwright (`post_data_buffer` is None):
  `add_init_script` a hook on `XMLHttpRequest.prototype.send` / `window.fetch`
  that logs `FormData.entries()` to console.
- Before capturing a *submit*, check whether a picker/query already lists the
  options you need (the audience picker response contained every
  `privacy_row_input`, no post required).

## Release checklist

- CHANGELOG section + version bump in `pyproject.toml` + tag + GitHub Release
  (`python ~/.claude/scripts/gh_release.py ship <repo> <version>` on the
  author's machine, or `gh release create`). A tag without a Release is
  invisible on the repo landing page.
- Single branch `main`; `git push origin main --tags`. `upstream`
  (`htlin222/fbpost`) is read-only reference; MIT credit lines in LICENSE and
  README stay (license obligation).
- Live E2E before tagging: schedule a SELF post with an image and a comment,
  list, delete with `--match`, and confirm the list is clean.

## Maintainer notes (the author's own setup — other users can ignore)

- After every real post or schedule, register it on the author's review site:
  `cd ~/Documents/Projects/review-site && python scripts/confirm_publish.py
  <slug> --post-id fb=<post_id>` (add `--schedule fb=<ISO time>` for scheduled
  posts). Without this the publication card stays "approved, not published"
  and goes red after the planned date.
- `fb snapshot` runs every 3 days at 03:00 via Task Scheduler `FbkitSnapshot`
  (silent on success, ntfy on failure). Snapshots live in
  `profiles/default/snapshots/` and are never committed.
- Post-analytics CSV → vault table: `fb report --out x.csv` then
  `scripts/report_to_md.py` (converts Pacific → Taipei).
- Check the audience column in `post-list-scheduled` before choosing a slot —
  a public post and a subscriber post at the same time do not compete.
