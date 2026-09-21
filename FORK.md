# unooffice: a downstream of UnoDOS

This repo carries **UnoOffice for Windows, macOS and Linux**:
UnoWord, UnoCalc and UnoShow built as native desktop apps from the UnoDOS
sources. The port itself lives in
[`pc64/uoffice/desktop/`](pc64/uoffice/desktop/README.md).

It is a downstream of [hmofet/unodos](https://github.com/hmofet/unodos) (the
upstream), under the same licence (MPL-2.0, see [`LICENSE`](LICENSE)). It
isn't a GitHub "fork" in the network sense only because GitHub doesn't let an
account fork its own repository. The history is shared, so branches move
between the two repos freely.

## Branches

| branch | what it is | who writes it |
|---|---|---|
| `master` | an exact mirror of upstream `master` | **only** the sync workflow. Never commit here |
| `main` (default) | upstream + this repo's work | you, via PRs |
| topic branches | changes meant for upstream | branch them off `master`, not `main` |

## Getting updates from upstream

[`.github/workflows/upstream-sync.yml`](.github/workflows/upstream-sync.yml)
runs every 6 hours (and on demand from the Actions tab). It:

1. fast-forwards `master` to upstream `master`;
2. merges `master` into `main`.

If the merge conflicts, it opens (or updates) an issue labelled
`upstream-sync` and leaves `main` alone. Resolve it by hand:

```bash
git fetch origin && git checkout main && git merge origin/master
# fix the conflicts, commit, push
```

## Where the two can drift

Everything outside the fork's own files (`FORK.md`, `.fork/`,
`upstream-sync.yml`, `upstream-pr.yml`) is meant to converge on upstream. It
stops converging in these ways:

1. **Work that hasn't landed upstream.** The desktop port and its
   installers landed upstream on 2026-09-21 (hmofet/unodos#1, a fast-forward,
   so the commits are identical in both repos). Anything committed straight to `main`
   and never sent upstream stays a permanent difference, so do the work on
   topic branches off `master` and send them.
2. **Upstream changing what the desktop shell uses.** `uodesk.c` and
   `uodesk_fs.c` reimplement pc64 services: the `UnoUuiApp` vtable,
   `pc64_shell_*`, `uno_fs_*`, the UEFI key codes and `pc64_uui.c`'s
   key-routing order. `CMakeLists.txt` also copies each app's source list from
   `pc64/build.sh`. A new source file upstream shows up as a link error. A
   *semantic* change (a new shell service, different key routing) compiles
   fine but behaves differently. The sync workflow re-runs the full build and
   install tests after every merge. Those catch the first kind and some of the
   second.
3. **Conflict resolutions.** A hand-resolved merge on `main` exists only
   here. Keep resolutions minimal and send any real fix upstream.
4. **Squash or rebase merges upstream.** AGENTS.md lands branches by
   rebase or squash, so upstream's commits for work done here have different
   hashes. The next sync merges identical content, which is usually clean but
   duplicates history. Anything edited here after sending conflicts.
5. **Build-only choices** made for the desktop and absent from pc64's own
   build: SDL2 pinned at 2.30.9, `FB_MAX` 3840x2400,
   `compat/uno_appdesc.h` (the Mach-O spelling of the app-descriptor macro;
   if upstream changes that macro, the Mac copy won't follow).
6. **Tags.** Upstream's `v*` tags are UnoDOS versions. This repo releases as
   `uoffice-v*`, and the sync doesn't copy tags.
7. **A rewritten upstream `master`** (a force-push) stops the mirror. It only
   fast-forwards, so it fails loudly. Fix it by hand:
   `git push --force origin upstream/master:master`, then merge into `main`.

## Sending changes upstream

Upstream PRs come from **topic branches cut from `master`**, so they carry
only the change and none of this repo's own files.

```bash
git checkout -b my-change origin/master
# ...commit...
git push -u origin my-change
.fork/upstream-pr.sh my-change "Title of the PR"   # needs gh logged in
```

Or run the **upstream-pr** workflow from the Actions tab with the branch
name. Either way the branch is pushed to `hmofet/unodos` under the same name,
and a PR is opened there against `master`. Both refuse a branch that contains
this repo's own files (`FORK.md`, `.fork/`, the two fork workflows) or isn't
based on upstream `master`.

The workflow needs a repo secret **`UPSTREAM_TOKEN`**: a fine-grained PAT
with *Contents: read/write* and *Pull requests: read/write* on
`hmofet/unodos`. The script uses your own `gh` login instead and needs no
secret.

Upstream's working agreement ([`AGENTS.md`](AGENTS.md)) still applies to
anything sent there: one lane per commit, rebased on `master`, gates green.
