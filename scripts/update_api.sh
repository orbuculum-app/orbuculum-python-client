#!/bin/bash
# Script to update Orbuculum Python client from latest OpenAPI specification
# This script should be run inside the Docker container

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
OPENAPI_JSON_URL="https://s1.orbuculum.app/swagger/json"
SPEC_FILE="/tmp/orbuculum-openapi.json"
BACKUP_DIR="/workspace/backups/backup_$(date +%Y%m%d_%H%M%S)"
WORKSPACE="/workspace"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Orbuculum API Client Update Tool${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Step 1: Download the latest OpenAPI specification
echo -e "${YELLOW}[1/5] Downloading latest OpenAPI specification...${NC}"
if curl -f -s -o "${SPEC_FILE}" "${OPENAPI_JSON_URL}"; then
    echo -e "${GREEN}✓ Downloaded successfully${NC}"
    
    # Extract and display API version
    API_VERSION=$(grep -o '"version":"[^"]*"' "${SPEC_FILE}" | cut -d'"' -f4)
    echo -e "  API Version: ${API_VERSION}"
else
    echo -e "${RED}✗ Failed to download OpenAPI specification from ${OPENAPI_JSON_URL}${NC}"
    exit 1
fi
echo ""

# Step 2: Create backup of existing code
echo -e "${YELLOW}[2/5] Creating backup of existing code...${NC}"
if [ -d "${WORKSPACE}/orbuculum_client" ]; then
    mkdir -p "${BACKUP_DIR}"
    cp -r "${WORKSPACE}/orbuculum_client" "${BACKUP_DIR}/"
    cp -r "${WORKSPACE}/docs" "${BACKUP_DIR}/" 2>/dev/null || true
    cp -r "${WORKSPACE}/.openapi-generator" "${BACKUP_DIR}/" 2>/dev/null || true
    echo -e "${GREEN}✓ Backup created at ${BACKUP_DIR}${NC}"
else
    echo -e "${YELLOW}⚠ No existing code found to backup${NC}"
fi
echo ""

# Step 2.5: Clean generated tests (preserve custom tests)
echo -e "${YELLOW}[2.5/5] Cleaning auto-generated tests...${NC}"
if [ -d "${WORKSPACE}/test/generated" ]; then
    rm -rf "${WORKSPACE}/test/generated"
    mkdir -p "${WORKSPACE}/test/generated"
    touch "${WORKSPACE}/test/generated/__init__.py"
    echo -e "${GREEN}✓ Generated tests cleaned${NC}"
else
    mkdir -p "${WORKSPACE}/test/generated"
    mkdir -p "${WORKSPACE}/test/custom"
    touch "${WORKSPACE}/test/generated/__init__.py"
    touch "${WORKSPACE}/test/custom/__init__.py"
    echo -e "${GREEN}✓ Test directory structure created${NC}"
fi
echo ""

# Step 3: Run OpenAPI Generator (once, to temp directory)
echo -e "${YELLOW}[3/5] Running OpenAPI Generator...${NC}"

# Check if openapi-generator-cli is available
if ! command -v openapi-generator-cli &> /dev/null && ! command -v openapi-generator &> /dev/null; then
    echo -e "${YELLOW}  Installing OpenAPI Generator CLI...${NC}"
    npm install -g @openapitools/openapi-generator-cli 2>/dev/null || {
        echo -e "${YELLOW}  Trying alternative installation method...${NC}"
        # Download JAR directly
        GENERATOR_JAR="/tmp/openapi-generator-cli.jar"
        curl -L https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.15.0/openapi-generator-cli-7.15.0.jar -o "${GENERATOR_JAR}"
        alias openapi-generator-cli="java -jar ${GENERATOR_JAR}"
    }
fi

# Generate to temporary directory (single generation)
TEMP_GEN_DIR="/tmp/orbuculum-gen-$(date +%s)"
echo -e "  Generating to temporary directory: ${TEMP_GEN_DIR}"

openapi-generator-cli generate \
    -i "${SPEC_FILE}" \
    -g python \
    -o "${TEMP_GEN_DIR}" \
    --package-name orbuculum_client \
    --library urllib3 \
    --additional-properties=projectName=orbuculum-api-client,packageVersion="${API_VERSION}" \
    || {
        echo -e "${RED}✗ OpenAPI Generator failed${NC}"
        echo -e "${YELLOW}  Restoring from backup...${NC}"
        if [ -d "${BACKUP_DIR}" ]; then
            rm -rf "${WORKSPACE}/orbuculum_client"
            cp -r "${BACKUP_DIR}/orbuculum_client" "${WORKSPACE}/"
        fi
        rm -rf "${TEMP_GEN_DIR}"
        exit 1
    }

echo -e "${GREEN}✓ Code generation completed${NC}"
echo ""

# Step 3.3: Copy generated files (respecting .openapi-generator-ignore)
echo -e "${YELLOW}[3.3/6] Copying generated files to workspace...${NC}"

# Read .openapi-generator-ignore patterns
IGNORE_PATTERNS=()
if [ -f "${WORKSPACE}/.openapi-generator-ignore" ]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^#.*$ ]] && continue
        [[ -z "$line" ]] && continue
        IGNORE_PATTERNS+=("$line")
    done < "${WORKSPACE}/.openapi-generator-ignore"
fi

# Function to check if file should be ignored
should_ignore() {
    local file="$1"
    for pattern in "${IGNORE_PATTERNS[@]}"; do
        # Simple pattern matching (supports basic wildcards)
        if [[ "$file" == $pattern ]]; then
            return 0  # Should ignore
        fi
    done
    return 1  # Should not ignore
}

# Copy package directory
if [ -d "${TEMP_GEN_DIR}/orbuculum_client" ]; then
    rm -rf "${WORKSPACE}/orbuculum_client"
    cp -r "${TEMP_GEN_DIR}/orbuculum_client" "${WORKSPACE}/"
    echo -e "${GREEN}✓ Copied orbuculum_client/${NC}"
fi

# Copy docs directory
if [ -d "${TEMP_GEN_DIR}/docs" ]; then
    rm -rf "${WORKSPACE}/docs"
    cp -r "${TEMP_GEN_DIR}/docs" "${WORKSPACE}/"
    echo -e "${GREEN}✓ Copied docs/${NC}"
fi

# Copy .openapi-generator directory
if [ -d "${TEMP_GEN_DIR}/.openapi-generator" ]; then
    rm -rf "${WORKSPACE}/.openapi-generator"
    cp -r "${TEMP_GEN_DIR}/.openapi-generator" "${WORKSPACE}/"
    echo -e "${GREEN}✓ Copied .openapi-generator/${NC}"
fi

# Copy test files (will organize later)
if [ -d "${TEMP_GEN_DIR}/test" ]; then
    # Copy test files to workspace
    cp -r "${TEMP_GEN_DIR}/test"/* "${WORKSPACE}/test/" 2>/dev/null || true
    echo -e "${GREEN}✓ Copied test files${NC}"
fi

# Note: Files in .openapi-generator-ignore (pyproject.toml, README.md, setup.py) are NOT copied
echo ""

# Step 3.4: Organize test files
echo -e "${YELLOW}[3.4/6] Organizing test files...${NC}"
if [ -d "${WORKSPACE}/test" ]; then
    # Move any test_*.py files from test/ root to test/generated/
    if ls "${WORKSPACE}/test"/test_*.py 1> /dev/null 2>&1; then
        mv "${WORKSPACE}/test"/test_*.py "${WORKSPACE}/test/generated/" 2>/dev/null || true
        echo -e "${GREEN}✓ Generated tests moved to test/generated/${NC}"
    else
        echo -e "${YELLOW}⚠ No test files found to move${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Test directory not found${NC}"
fi
echo ""

# Step 3.5: Sync version information
echo -e "${YELLOW}[3.5/6] Syncing version information...${NC}"

# Read current client version from pyproject.toml
CLIENT_VERSION=$(grep -m1 '^version = ' "${WORKSPACE}/pyproject.toml" | cut -d'"' -f2)

if [ -n "${CLIENT_VERSION}" ]; then
    echo -e "  Client version from pyproject.toml: ${CLIENT_VERSION}"
    echo -e "  API version from OpenAPI spec: ${API_VERSION}"
    
    # Update __init__.py with correct versions
    sed -i.bak "s/__version__ = \".*\"/__version__ = \"${CLIENT_VERSION}\"/" "${WORKSPACE}/orbuculum_client/__init__.py"
    
    # Add __api_version__ and __api_supported__ after __version__ if they don't exist
    if ! grep -q "__api_version__" "${WORKSPACE}/orbuculum_client/__init__.py"; then
        sed -i.bak "/__version__ = /a\\
__api_version__ = \"${API_VERSION}\"\\
__api_supported__ = \"${API_VERSION}\"
" "${WORKSPACE}/orbuculum_client/__init__.py"
    else
        # If they exist, update them
        sed -i.bak "s/__api_version__ = \".*\"/__api_version__ = \"${API_VERSION}\"/" "${WORKSPACE}/orbuculum_client/__init__.py"
        sed -i.bak "s/__api_supported__ = \".*\"/__api_supported__ = \"${API_VERSION}\"/" "${WORKSPACE}/orbuculum_client/__init__.py"
    fi
    
    # Remove backup files
    rm -f "${WORKSPACE}/orbuculum_client/__init__.py.bak"
    
    echo -e "${GREEN}✓ Version information synchronized${NC}"
    echo -e "  __version__ = \"${CLIENT_VERSION}\""
    echo -e "  __api_version__ = \"${API_VERSION}\""
    echo -e "  __api_supported__ = \"${API_VERSION}\""
else
    echo -e "${YELLOW}⚠ Warning: Could not read version from pyproject.toml${NC}"
fi
echo ""

# Step 3.6: Update README.md API sections
echo -e "${YELLOW}[3.6/6] Updating README.md API documentation sections...${NC}"

if [ -f "${TEMP_GEN_DIR}/README.md" ]; then
    # Use Python to extract and update README sections
    python3 << EOF
import re

# Read current README
with open('/workspace/README.md', 'r') as f:
    content = f.read()

# Read generated README from temp directory
with open('${TEMP_GEN_DIR}/README.md', 'r') as f:
    temp_content = f.read()

# Extract API Endpoints section
api_match = re.search(r'## Documentation for API Endpoints.*?(?=\n## Documentation For Models)', temp_content, re.DOTALL)
if api_match:
    new_api_section = api_match.group(0)
    # Replace in current README
    content = re.sub(
        r'## Documentation for API Endpoints.*?(?=\n## Documentation For Models)',
        new_api_section,
        content,
        flags=re.DOTALL
    )

# Extract Models section
models_match = re.search(r'## Documentation For Models.*?(?=\n<a id="documentation-for-authorization">)', temp_content, re.DOTALL)
if models_match:
    new_models_section = models_match.group(0)
    # Replace in current README
    content = re.sub(
        r'## Documentation For Models.*?(?=\n<a id="documentation-for-authorization">)',
        new_models_section,
        content,
        flags=re.DOTALL
    )

# Write updated README
with open('/workspace/README.md', 'w') as f:
    f.write(content)

print("✓ README.md sections updated")
EOF
    
    echo -e "${GREEN}✓ README.md API sections updated${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Generated README not found${NC}"
fi

# Cleanup temporary generation directory
rm -rf "${TEMP_GEN_DIR}"
echo -e "  Cleaned up temporary directory"
echo ""

# Step 4: Verify generated code
echo -e "${YELLOW}[4/6] Verifying generated code...${NC}"
if [ -f "${WORKSPACE}/orbuculum_client/__init__.py" ]; then
    echo -e "${GREEN}✓ Generated code structure looks good${NC}"
    
    # Try to import the module
    cd "${WORKSPACE}"
    if python3 -c "import orbuculum_client; print(f'  Version: {orbuculum_client.__version__}')" 2>/dev/null; then
        echo -e "${GREEN}✓ Module imports successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Module import test failed (this might be normal if dependencies are not installed)${NC}"
    fi
else
    echo -e "${RED}✗ Generated code is incomplete${NC}"
    exit 1
fi
echo ""

# Step 5: Summary
echo -e "${YELLOW}[5/6] Update Summary${NC}"
echo -e "${GREEN}✓ OpenAPI specification downloaded from: ${OPENAPI_JSON_URL}${NC}"
echo -e "${GREEN}✓ Client code regenerated for version: ${API_VERSION}${NC}"
echo -e "${GREEN}✓ Backup available at: ${BACKUP_DIR}${NC}"
echo ""

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${GREEN}================================${NC}"
echo "1. Review the changes:"
echo "   git diff"
echo ""
echo "2. Check version synchronization:"
echo "   grep -A2 '__version__' orbuculum_client/__init__.py"
echo "   grep '^version' pyproject.toml"
echo ""
echo "3. Update client version in pyproject.toml if this is a new release"
echo "   (API version is already synced automatically)"
echo ""
echo "4. Test the client:"
echo "   docker-compose run --rm dev pytest"
echo ""
echo "5. Build the package:"
echo "   docker-compose run --rm builder"
echo ""
echo "6. If everything looks good, commit the changes:"
echo "   git add ."
echo "   git commit -m \"Update API client to version ${API_VERSION}\""
echo ""
echo -e "${YELLOW}If something went wrong, restore from backup:${NC}"
echo "   rm -rf orbuculum_client"
echo "   cp -r ${BACKUP_DIR}/orbuculum_client ."
echo ""
echo -e "${YELLOW}Note: All backups are stored in the backups/ directory${NC}"
echo ""
