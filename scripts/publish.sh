#!/bin/bash
# Script to publish Orbuculum Python client to PyPI or TestPyPI
# This script automates the entire publishing workflow

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE="/workspace"
DIST_DIR="${WORKSPACE}/dist"
PYPROJECT_FILE="${WORKSPACE}/pyproject.toml"
INIT_FILE="${WORKSPACE}/orbuculum_client/__init__.py"

# Default values
TARGET=""
DRY_RUN=false
NO_GIT=false
SKIP_TESTS=false
SKIP_BUILD=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        pypi|testpypi)
            TARGET="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-git)
            NO_GIT=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [pypi|testpypi] [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run      Show what would be done without actually doing it"
            echo "  --no-git       Skip git operations (automatic for testpypi)"
            echo "  --skip-tests   Skip running tests"
            echo "  --skip-build   Skip building (use existing dist/)"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "Note: Git operations are automatically disabled for testpypi target."
            echo ""
            echo "Examples:"
            echo "  $0 testpypi              # Publish to TestPyPI (no git tags)"
            echo "  $0 pypi                  # Publish to PyPI (creates git tag)"
            echo "  $0 pypi --dry-run        # Dry run for PyPI"
            echo "  $0 pypi --no-git         # Publish to PyPI without git operations"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate target
if [[ -z "$TARGET" ]]; then
    echo -e "${RED}Error: Target not specified${NC}"
    echo "Usage: $0 [pypi|testpypi] [OPTIONS]"
    echo "Use --help for more information"
    exit 1
fi

# Set repository URL based on target
if [[ "$TARGET" == "testpypi" ]]; then
    REPO_URL="https://test.pypi.org/legacy/"
    REPO_NAME="testpypi"
    PACKAGE_URL_BASE="https://test.pypi.org/project"
    # Automatically skip git operations for TestPyPI (testing environment)
    if [[ "$NO_GIT" == false ]]; then
        NO_GIT=true
        echo -e "${YELLOW}Note: Git operations automatically disabled for TestPyPI${NC}"
    fi
else
    REPO_URL="https://upload.pypi.org/legacy/"
    REPO_NAME="pypi"
    PACKAGE_URL_BASE="https://pypi.org/project"
fi

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Orbuculum Package Publisher${NC}"
echo -e "${BLUE}================================${NC}"
echo -e "Target: ${YELLOW}${TARGET}${NC}"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "Mode: ${YELLOW}DRY RUN${NC}"
fi
if [[ "$NO_GIT" == true ]]; then
    echo -e "Git operations: ${YELLOW}DISABLED${NC}"
fi
echo ""

# Step 1: Extract and validate version
echo -e "${YELLOW}[1/8] Extracting version information...${NC}"
VERSION=$(grep -E '^version = ' "$PYPROJECT_FILE" | cut -d'"' -f2)
if [[ -z "$VERSION" ]]; then
    echo -e "${RED}✗ Failed to extract version from pyproject.toml${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Client version: ${VERSION}${NC}"

# Check version in __init__.py
INIT_VERSION=$(grep -E '^__version__ = ' "$INIT_FILE" | cut -d'"' -f2)
if [[ "$VERSION" != "$INIT_VERSION" ]]; then
    echo -e "${RED}✗ Version mismatch!${NC}"
    echo -e "  pyproject.toml: ${VERSION}"
    echo -e "  __init__.py.__version__: ${INIT_VERSION}"
    exit 1
fi
echo -e "${GREEN}✓ Version consistent across files${NC}"

# Extract API version (optional - for information only)
API_VERSION=$(grep -E '^__api_supported__ = ' "$INIT_FILE" | cut -d'"' -f2)
if [[ -n "$API_VERSION" ]]; then
    echo -e "${GREEN}✓ Supports API version: ${API_VERSION}${NC}"
else
    echo -e "${YELLOW}⚠ API version metadata not found (legacy mode)${NC}"
fi
echo ""

# Step 2: Check git status (if not skipped)
if [[ "$NO_GIT" == false ]]; then
    echo -e "${YELLOW}[2/8] Checking git status...${NC}"
    
    # Check if we're in a git repo
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Not a git repository, skipping git checks${NC}"
        NO_GIT=true
    else
        # Check for uncommitted changes
        if ! git diff-index --quiet HEAD --; then
            echo -e "${RED}✗ Git working directory has uncommitted changes${NC}"
            echo -e "${YELLOW}Please commit or stash your changes first${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Git working directory is clean${NC}"
        
        # Check if tag already exists
        if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠ Git tag v${VERSION} already exists${NC}"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    fi
    echo ""
else
    echo -e "${YELLOW}[2/8] Skipping git checks (--no-git)${NC}"
    echo ""
fi

# Step 3: Run tests (if not skipped)
if [[ "$SKIP_TESTS" == false ]]; then
    echo -e "${YELLOW}[3/8] Running tests...${NC}"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}[DRY RUN] Would run: pytest${NC}"
    else
        if command -v pytest &> /dev/null; then
            if pytest; then
                echo -e "${GREEN}✓ All tests passed${NC}"
            else
                echo -e "${RED}✗ Tests failed${NC}"
                exit 1
            fi
        else
            echo -e "${YELLOW}⚠ pytest not found, skipping tests${NC}"
        fi
    fi
    echo ""
else
    echo -e "${YELLOW}[3/8] Skipping tests (--skip-tests)${NC}"
    echo ""
fi

# Step 4: Clean build artifacts (ensures only fresh build is published)
echo -e "${YELLOW}[4/8] Cleaning build artifacts...${NC}"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}[DRY RUN] Would clean: ${DIST_DIR}, build/, *.egg-info${NC}"
    echo -e "${BLUE}[DRY RUN] This ensures only the fresh build is published${NC}"
else
    if [[ "$SKIP_BUILD" == false ]]; then
        # Count existing files before cleaning
        if [[ -d "${DIST_DIR}" ]]; then
            FILE_COUNT=$(ls -1 "${DIST_DIR}" 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$FILE_COUNT" -gt 0 ]]; then
                echo -e "  Removing ${FILE_COUNT} existing file(s) from dist/"
            fi
        fi
        
        # Clean dist, build, and egg-info directories
        rm -rf "${DIST_DIR}"
        rm -rf "${WORKSPACE}/build"
        rm -rf "${WORKSPACE}"/*.egg-info
        
        mkdir -p "${DIST_DIR}"
        echo -e "${GREEN}✓ Build artifacts cleaned (ensures fresh build)${NC}"
    else
        echo -e "${YELLOW}⚠ Skipping clean (--skip-build)${NC}"
        echo -e "${YELLOW}⚠ Warning: Using existing build from dist/${NC}"
    fi
fi
echo ""

# Step 5: Build package
if [[ "$SKIP_BUILD" == false ]]; then
    echo -e "${YELLOW}[5/8] Building package...${NC}"
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${BLUE}[DRY RUN] Would run: python -m build${NC}"
    else
        cd "$WORKSPACE"
        python -m build --wheel --sdist --outdir "$DIST_DIR"
        echo -e "${GREEN}✓ Package built successfully${NC}"
        
        # List built files
        echo -e "${GREEN}Built files:${NC}"
        ls -lh "$DIST_DIR"
    fi
    echo ""
else
    echo -e "${YELLOW}[5/8] Skipping build (--skip-build)${NC}"
    if [[ ! -d "$DIST_DIR" ]] || [[ -z "$(ls -A $DIST_DIR)" ]]; then
        echo -e "${RED}✗ No existing build found in ${DIST_DIR}${NC}"
        exit 1
    fi
    echo ""
fi

# Step 6: Confirmation
echo -e "${YELLOW}[6/8] Publishing confirmation${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Package:        ${GREEN}orbuculum-client${NC}"
echo -e "Client Version: ${GREEN}${VERSION}${NC}"
if [[ -n "$API_VERSION" ]]; then
    echo -e "Supports API:   ${GREEN}${API_VERSION}${NC}"
fi
echo -e "Target:         ${GREEN}${TARGET}${NC}"
echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}[DRY RUN] Skipping confirmation${NC}"
else
    read -p "Proceed with upload? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Aborted by user${NC}"
        exit 0
    fi
fi
echo ""

# Step 7: Upload to PyPI/TestPyPI
echo -e "${YELLOW}[7/8] Uploading to ${TARGET}...${NC}"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}[DRY RUN] Would run: twine upload --repository ${REPO_NAME} dist/*${NC}"
else
    if ! command -v twine &> /dev/null; then
        echo -e "${RED}✗ twine not found${NC}"
        echo -e "Install it with: pip install twine"
        exit 1
    fi
    
    if twine upload --repository "$REPO_NAME" "${DIST_DIR}"/*; then
        echo -e "${GREEN}✓ Package uploaded successfully${NC}"
        echo -e "${GREEN}Project page: ${PACKAGE_URL_BASE}/orbuculum/${NC}"
        echo -e "${GREEN}This version: ${PACKAGE_URL_BASE}/orbuculum/${VERSION}/${NC}"
    else
        echo -e "${RED}✗ Upload failed${NC}"
        exit 1
    fi
fi
echo ""

# Step 8: Git tagging (if not skipped)
if [[ "$NO_GIT" == false ]] && [[ "$DRY_RUN" == false ]]; then
    echo -e "${YELLOW}[8/8] Creating git tag...${NC}"
    
    if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠ Tag v${VERSION} already exists, skipping${NC}"
    else
        TAG_MSG="Release ${VERSION}"
        if [[ -n "$API_VERSION" ]]; then
            TAG_MSG="${TAG_MSG} - Supports API ${API_VERSION}"
        fi
        git tag -a "v${VERSION}" -m "${TAG_MSG}"
        echo -e "${GREEN}✓ Created tag v${VERSION}${NC}"
        
        read -p "Push tag to origin? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git push origin "v${VERSION}"
            echo -e "${GREEN}✓ Tag pushed to origin${NC}"
        fi
    fi
else
    echo -e "${YELLOW}[8/8] Skipping git operations${NC}"
fi
echo ""

# Success summary
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✓ Publishing Complete!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "Package:        ${GREEN}orbuculum${NC}"
echo -e "Client Version: ${GREEN}${VERSION}${NC}"
if [[ -n "$API_VERSION" ]]; then
    echo -e "Supports API:   ${GREEN}${API_VERSION}${NC}"
fi
echo -e "Target:         ${GREEN}${TARGET}${NC}"
echo ""

if [[ "$DRY_RUN" == false ]]; then
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Test installation:"
    if [[ "$TARGET" == "testpypi" ]]; then
        echo "   pip install -i https://test.pypi.org/simple/ orbuculum==${VERSION}"
    else
        echo "   pip install orbuculum==${VERSION}"
    fi
    echo ""
    echo "2. Verify the package works:"
    echo "   python -c 'import orbuculum; print(f\"Client: {orbuculum.__version__}, API: {orbuculum.__api_supported__}\")'"
    echo ""
    echo "3. Check the package page:"
    echo "   ${PACKAGE_URL_BASE}/orbuculum/"
fi
