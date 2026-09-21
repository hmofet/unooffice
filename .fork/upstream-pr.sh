#!/bin/sh
# Open a PR on the upstream (hmofet/unodos) from a topic branch of this repo.
# See FORK.md.
#
#   .fork/upstream-pr.sh <branch> "<title>" [body-file]
#
# The branch must already be pushed to origin and be cut from `master` (the
# upstream mirror).  It is pushed to upstream under the same name, and the PR
# targets upstream master.  Auth: your `gh` login locally; in CI, GH_TOKEN
# must be a token that can write to hmofet/unodos (UPSTREAM_TOKEN).
set -e
UPSTREAM=hmofet/unodos
BR=$1; TITLE=$2; BODYF=$3
[ -n "$BR" ] && [ -n "$TITLE" ] || { echo "usage: $0 <branch> <title> [body-file]" >&2; exit 2; }

git fetch -q --no-tags "https://github.com/$UPSTREAM.git" master
UP=$(git rev-parse FETCH_HEAD)
git fetch -q origin "$BR"
TIP=$(git rev-parse FETCH_HEAD)

# nothing of this repo's own may travel upstream
FORK_ONLY='^(FORK\.md|\.fork/|\.github/workflows/upstream-(sync|pr)\.yml)'
bad=$(git diff --name-only "$UP...$TIP" | grep -E "$FORK_ONLY" || true)
if [ -n "$bad" ]; then
    echo "refusing: $BR carries this repo's own files:" >&2
    echo "$bad" >&2
    echo "cut the branch from origin/master, not main (FORK.md)" >&2
    exit 1
fi
# ...and nothing of main's that upstream does not have yet
if git merge-base --is-ancestor origin/main "$TIP" 2>/dev/null; then
    echo "refusing: $BR contains all of main - cut it from origin/master" >&2
    exit 1
fi
[ -n "$(git rev-list "$UP..$TIP")" ] || { echo "$BR has nothing upstream lacks" >&2; exit 1; }

if [ -n "$GH_TOKEN" ]; then
    URL="https://x-access-token:$GH_TOKEN@github.com/$UPSTREAM.git"
else
    URL="https://github.com/$UPSTREAM.git"       # gh's credential helper
fi
git push -q "$URL" "$TIP:refs/heads/$BR"

if [ -n "$(gh pr list -R "$UPSTREAM" --head "$BR" --state open --json number -q '.[0].number')" ]; then
    echo "branch updated; the open PR on $UPSTREAM already tracks it"
    exit 0
fi
if [ -n "$BODYF" ]; then
    gh pr create -R "$UPSTREAM" -B master -H "$BR" -t "$TITLE" -F "$BODYF"
else
    gh pr create -R "$UPSTREAM" -B master -H "$BR" -t "$TITLE" \
        -b "From the downstream [hmofet/unooffice](https://github.com/hmofet/unooffice), branch \`$BR\`."
fi
