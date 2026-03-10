#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 <version_name> [build_number]"
  echo "  Example: $0 1.0.3"
  echo "  Example: $0 1.0.3 5"
  exit 1
fi

VERSION_NAME="$1"

if [ $# -eq 2 ]; then
  BUILD_NUMBER="$2"
else
  CURRENT=$(grep '^version:' pubspec.yaml | head -1 | sed 's/.*+//')
  BUILD_NUMBER=$((CURRENT + 1))
fi

sed -i "s/^version: .*/version: ${VERSION_NAME}+${BUILD_NUMBER}/" pubspec.yaml
echo "pubspec.yaml -> version: ${VERSION_NAME}+${BUILD_NUMBER}"

flutter pub get

git add pubspec.yaml pubspec.lock
git commit -m "chore: bump version to ${VERSION_NAME}+${BUILD_NUMBER}"

git tag "v${VERSION_NAME}"
git push origin HEAD
git push origin "v${VERSION_NAME}"

echo "Released v${VERSION_NAME}!"
