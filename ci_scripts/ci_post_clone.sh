#!/bin/sh
set -e

cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "=== Buzz version resolution ==="

if [ -n "$CI_TAG" ]; then
  VERSION=$(echo "$CI_TAG" | sed 's/^v//')
  echo "Source: CI_TAG ($CI_TAG) -> $VERSION"
else
  echo "No CI_TAG set, resolving version from git tags..."

  echo "Fetching tags from remote..."
  git fetch origin --tags --force 2>&1 || true

  VERSION=$(git tag 2>/dev/null \
    | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' \
    | sed 's/^v//' \
    | sort -t. -k1,1n -k2,2n -k3,3n \
    | tail -1)

  if [ -n "$VERSION" ]; then
    echo "Source: git fetch --tags -> $VERSION"
  else
    echo "Local tags empty, querying remote..."
    VERSION=$(git ls-remote --tags origin 2>/dev/null \
      | grep -oE 'refs/tags/v?[0-9]+\.[0-9]+\.[0-9]+$' \
      | sed 's|refs/tags/||; s/^v//' \
      | sort -t. -k1,1n -k2,2n -k3,3n \
      | tail -1)

    if [ -n "$VERSION" ]; then
      echo "Source: git ls-remote -> $VERSION"
    else
      echo "ERROR: No version tags found via any method. Keeping MARKETING_VERSION as-is."
      exit 0
    fi
  fi
fi

echo "Setting MARKETING_VERSION to $VERSION"

sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/g" Buzz.xcodeproj/project.pbxproj

RESULT=$(grep -c "MARKETING_VERSION = $VERSION;" Buzz.xcodeproj/project.pbxproj || true)
echo "Verified: $RESULT occurrences of MARKETING_VERSION = $VERSION; in project.pbxproj"

echo "=== Done ==="
