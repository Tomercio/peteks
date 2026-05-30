#!/usr/bin/env bash
# Usage: ./scripts/bump_version.sh [major|minor|patch]
set -e

BUMP=${1:-patch}
PUBSPEC="pubspec.yaml"

# Read current version line, e.g. "version: 1.2.3+45"
CURRENT=$(grep '^version:' "$PUBSPEC" | head -1 | awk '{print $2}')
VERSION="${CURRENT%+*}"   # "1.2.3"
BUILD="${CURRENT#*+}"     # "45"

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

case "$BUMP" in
  major) MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR+1)); PATCH=0 ;;
  patch) PATCH=$((PATCH+1)) ;;
  *)
    echo "Usage: $0 [major|minor|patch]"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
NEW_BUILD=$((BUILD+1))
NEW_FULL="$NEW_VERSION+$NEW_BUILD"

# Update pubspec.yaml
sed -i "s/^version: .*/version: $NEW_FULL/" "$PUBSPEC"

echo "Bumped: $CURRENT → $NEW_FULL"

# Commit and tag
git add "$PUBSPEC"
git commit -m "chore: bump version to $NEW_FULL"
git tag "v$NEW_VERSION"

echo ""
echo "Done! Now run:"
echo "  git push && git push --tags"
echo "to trigger the GitHub Actions release workflow."
