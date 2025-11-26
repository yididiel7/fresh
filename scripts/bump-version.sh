#!/bin/bash

# Version bump script for the editor project
# This script updates the version in Cargo.toml and Cargo.lock
# but does NOT commit, tag, or push - that's left for you to do manually

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print usage
usage() {
    echo "Usage: $0 [patch|minor|major]"
    echo ""
    echo "Examples:"
    echo "  $0          # Bump patch version (default): 0.1.0 -> 0.1.1"
    echo "  $0 patch    # Bump patch version: 0.1.0 -> 0.1.1"
    echo "  $0 minor    # Bump minor version: 0.1.0 -> 0.2.0"
    echo "  $0 major    # Bump major version: 0.1.0 -> 1.0.0"
    echo ""
    echo "The script will:"
    echo "  1. Read current version from Cargo.toml"
    echo "  2. Calculate the new version"
    echo "  3. Ask for confirmation"
    echo "  4. Update Cargo.toml and Cargo.lock"
    echo ""
    echo "After running this script, you should:"
    echo "  1. Review the changes"
    echo "  2. Commit: git add Cargo.toml Cargo.lock && git commit -m 'Bump version to X.Y.Z'"
    echo "  3. Tag: git tag vX.Y.Z"
    echo "  4. Push: git push origin main && git push origin vX.Y.Z"
    exit 1
}

# Check if we're in the project root
if [ ! -f "Cargo.toml" ]; then
    echo -e "${RED}Error: Cargo.toml not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(grep '^version = ' Cargo.toml | head -1 | sed 's/version = "\(.*\)"/\1/')

# Strip any pre-release suffix for version calculation
BASE_VERSION=$(echo "$CURRENT_VERSION" | sed 's/-.*//')

# Parse version components
MAJOR=$(echo "$BASE_VERSION" | cut -d. -f1)
MINOR=$(echo "$BASE_VERSION" | cut -d. -f2)
PATCH=$(echo "$BASE_VERSION" | cut -d. -f3)

# Determine bump type (default to patch)
BUMP_TYPE="${1:-patch}"

# Calculate new version based on bump type
case "$BUMP_TYPE" in
    patch)
        NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"
        ;;
    minor)
        NEW_VERSION="$MAJOR.$((MINOR + 1)).0"
        ;;
    major)
        NEW_VERSION="$((MAJOR + 1)).0.0"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo -e "${RED}Error: Invalid bump type '$BUMP_TYPE'${NC}"
        echo "Valid options: patch, minor, major"
        exit 1
        ;;
esac

echo -e "${BLUE}Version Bump ($BUMP_TYPE)${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Current version: ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "New version:     ${GREEN}$NEW_VERSION${NC}"
echo ""

# Ask for confirmation
read -p "Bump $BUMP_TYPE version $CURRENT_VERSION -> $NEW_VERSION? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo -e "${BLUE}Step 1:${NC} Updating Cargo.toml..."

# Update version in Cargo.toml
sed -i.bak "0,/^version = \".*\"/{s/^version = \".*\"/version = \"$NEW_VERSION\"/}" Cargo.toml
rm Cargo.toml.bak

echo -e "${GREEN}✓${NC} Updated Cargo.toml"

echo ""
echo -e "${BLUE}Step 2:${NC} Updating Cargo.lock (running cargo build)..."

# Update Cargo.lock by running cargo build
if cargo build --quiet 2>&1 | head -20; then
    echo -e "${GREEN}✓${NC} Updated Cargo.lock"
else
    echo -e "${YELLOW}Warning:${NC} cargo build had some output (this might be normal)"
fi

echo ""
echo -e "${BLUE}Step 3:${NC} Summary of changes..."
echo ""

# Show the diff
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Git diff:"
    git diff Cargo.toml Cargo.lock
else
    echo "Changes made to:"
    echo "  - Cargo.toml (version: $CURRENT_VERSION -> $NEW_VERSION)"
    echo "  - Cargo.lock (updated)"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Ask for confirmation to commit, tag, and push
read -p "Commit, tag, and push v$NEW_VERSION? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Changes made but not committed.${NC}"
    echo ""
    echo "To complete manually:"
    echo -e "  1. Commit changes: ${YELLOW}git add Cargo.toml Cargo.lock && git commit -m 'Bump version to $NEW_VERSION'${NC}"
    echo -e "  2. Create tag:     ${YELLOW}git tag v$NEW_VERSION${NC}"
    echo -e "  3. Push:           ${YELLOW}git push && git push origin v$NEW_VERSION${NC}"
    exit 0
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo ""
echo -e "${BLUE}Step 4:${NC} Committing changes..."
git add Cargo.toml Cargo.lock
git commit -m "Bump version to $NEW_VERSION"
echo -e "${GREEN}✓${NC} Committed"

echo ""
echo -e "${BLUE}Step 5:${NC} Creating tag v$NEW_VERSION..."
git tag "v$NEW_VERSION"
echo -e "${GREEN}✓${NC} Tagged"

echo ""
echo -e "${BLUE}Step 6:${NC} Pushing to origin..."
git push origin "$CURRENT_BRANCH"
git push origin "v$NEW_VERSION"
echo -e "${GREEN}✓${NC} Pushed"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Version $NEW_VERSION released!${NC}"
echo ""
echo "The GitHub Actions workflow will automatically create a release from the tag."
