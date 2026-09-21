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
