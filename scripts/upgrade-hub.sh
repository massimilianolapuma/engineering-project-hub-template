#!/usr/bin/env bash
# Pins this repository to a hub release: ./scripts/upgrade-hub.sh v0.18.0
# Replaces the release commit in every workflow that uses the hub. Read the hub CHANGELOG first:
# https://github.com/massimilianolapuma/engineering-project-hub/blob/main/CHANGELOG.md
set -euo pipefail
tag="${1:?usage: $0 vX.Y.Z}"
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "not a release tag: $tag" >&2; exit 1; }
sha=$(git ls-remote https://github.com/massimilianolapuma/engineering-project-hub.git "refs/tags/$tag^{}" "refs/tags/$tag" |
  awk 'NR == 1 { print $1 }')
[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || { echo "tag not found: $tag" >&2; exit 1; }
for f in .github/workflows/deploy-hub.yml .github/workflows/validate-config.yml; do
  # Only the hub lines: the reusable workflow pin, hub-ref, and the ref marked "hub release".
  SHA="$sha" TAG="$tag" perl -pi -e '
    s/(rw-hub-cloudflare-deploy\.yml@)[0-9a-f]{40} # v[0-9.]+/${1}$ENV{SHA} # $ENV{TAG}/;
    s/(hub-ref: )[0-9a-f]{40}/${1}$ENV{SHA}/;
    s/(ref: )[0-9a-f]{40} # v[0-9.]+( hub release)/${1}$ENV{SHA} # $ENV{TAG}${2}/;
  ' "$f"
done
echo "Pinned to $tag ($sha). Review the diff, commit, push."
