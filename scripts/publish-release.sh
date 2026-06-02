#!/bin/bash

# Handed Release Publisher
# Handles git tagging, merging (if needed), and publishing to GitHub Releases

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$PROJECT_DIR/dist"
VERSION="2.1.0"
REPO="aydencharles/dnsmasqGUI"
ZIP_NAME="Handed-v${VERSION}-macOS.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"

echo "=== Handed Release Publisher ==="
echo "Version: $VERSION"
echo "Repository: $REPO"
echo ""

# Ensure ZIP asset exists
if [ ! -f "$ZIP_PATH" ]; then
    echo "Error: Release asset not found at $ZIP_PATH"
    echo "Please run 'make release' first to build the release archive."
    exit 1
fi

# Check for GITHUB_TOKEN
if [ -z "$GITHUB_TOKEN" ] || [ "$GITHUB_TOKEN" = "github_pat_antigravitydummytoken" ]; then
    echo "GitHub Personal Access Token is required."
    read -sp "Enter your GitHub Personal Access Token (PAT): " GITHUB_TOKEN
    echo ""
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "Error: GitHub token cannot be empty."
        exit 1
    fi
fi

# Confirm tag and release
TAG="v$VERSION"
echo "This script will:"
echo "1. Push the local tag $TAG to origin"
echo "2. Create a GitHub Release for tag $TAG"
echo "3. Upload $ZIP_NAME to the release"
echo ""
read -p "Do you want to proceed? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release publication cancelled."
    exit 0
fi

# Ensure tag is created locally (if not already)
if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Creating git tag $TAG..."
    git tag -a "$TAG" -m "Release $TAG with i18n support"
else
    echo "Tag $TAG already exists locally."
fi

# Push tag to GitHub
echo "Pushing tag $TAG to origin..."
git push origin "$TAG"

# Create release on GitHub
echo "Creating release on GitHub..."
RELEASE_JSON=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO/releases \
  -d "{
    \"tag_name\": \"$TAG\",
    \"target_commitish\": \"public\",
    \"name\": \"$TAG\",
    \"body\": \"Handed $TAG - Native macOS GUI for dnsmasq with dynamic localization support for English and Simplified Chinese.\",
    \"draft\": false,
    \"prerelease\": false
  }")

# Check for release creation error
RELEASE_ID=$(echo "$RELEASE_JSON" | grep -m 1 "\"id\":" | sed -E 's/.*"id": ([0-9]+),.*/\1/')

if [ -z "$RELEASE_ID" ] || [[ "$RELEASE_ID" =~ [^0-9] ]]; then
    echo "Error creating release. Response:"
    echo "$RELEASE_JSON"
    exit 1
fi

echo "Created release ID: $RELEASE_ID"

# Upload release asset
echo "Uploading asset $ZIP_NAME..."
UPLOAD_URL="https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$ZIP_NAME"

UPLOAD_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: application/zip" \
  --data-binary @"$ZIP_PATH" \
  "$UPLOAD_URL")

ASSET_ID=$(echo "$UPLOAD_RESPONSE" | grep -m 1 "\"id\":" | sed -E 's/.*"id": ([0-9]+),.*/\1/')

if [ -z "$ASSET_ID" ] || [[ "$ASSET_ID" =~ [^0-9] ]]; then
    echo "Error uploading asset. Response:"
    echo "$UPLOAD_RESPONSE"
    exit 1
fi

echo "Successfully uploaded asset. Asset ID: $ASSET_ID"
echo "=== Release published successfully! ==="
