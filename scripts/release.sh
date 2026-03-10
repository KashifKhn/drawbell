#!/usr/bin/env bash
set -euo pipefail

BUMP="${1:-patch}"

if [[ "$BUMP" != "patch" && "$BUMP" != "minor" && "$BUMP" != "major" ]]; then
  echo "Usage: $0 [patch|minor|major]"
  echo "  Default: patch"
  exit 1
fi

CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
CURRENT_BUILD=$(grep '^version:' pubspec.yaml | sed 's/.*+//')

MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)

case "$BUMP" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

VERSION_NAME="${MAJOR}.${MINOR}.${PATCH}"
BUILD_NUMBER=$((CURRENT_BUILD + 1))
TAG="v${VERSION_NAME}"

if git tag | grep -q "^${TAG}$"; then
  echo "Error: tag '${TAG}' already exists locally. Delete it first: git tag -d ${TAG}"
  exit 1
fi

if git ls-remote --tags origin | grep -q "refs/tags/${TAG}$"; then
  echo "Error: tag '${TAG}' already exists on remote. Use a different version."
  exit 1
fi

sed -i "s/^version: .*/version: ${VERSION_NAME}+${BUILD_NUMBER}/" pubspec.yaml
echo "pubspec.yaml -> version: ${VERSION_NAME}+${BUILD_NUMBER}"

flutter pub get

git add pubspec.yaml pubspec.lock
git commit -m "chore: bump version to ${VERSION_NAME}+${BUILD_NUMBER}"

git tag "$TAG"
git push origin HEAD
git push origin "$TAG"

echo "Released ${TAG}!"
