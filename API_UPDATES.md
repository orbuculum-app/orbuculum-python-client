# API Updates Guide

This guide explains how to update the Orbuculum Python client when the API specification changes.

## Overview

The Orbuculum Python client is automatically generated from the [OpenAPI specification](https://s1.orbuculum.app/swagger/json) using [OpenAPI Generator](https://openapi-generator.tech). When the API is updated, you need to regenerate the client code to reflect the changes.

## Automatic Update Using Docker

The easiest way to update the client is using the provided Docker automation script:

```bash
docker-compose run --rm updater
```

This command will:
1. Download the latest OpenAPI specification from `https://s1.orbuculum.app/swagger/json`
2. Create a backup of the current code
3. Regenerate the client code using OpenAPI Generator 7.15.0
4. **Automatically synchronize version information** (see below)
5. Verify the generated code
6. Provide next steps for testing and committing

### What the Script Does

The update script (`scripts/update_api.sh`) performs the following steps:

1. **Download Spec**: Fetches the latest OpenAPI JSON from the API server
2. **Backup**: Creates a timestamped backup in `backups/backup_YYYYMMDD_HHMMSS/`
3. **Generate**: Runs OpenAPI Generator with the correct parameters
4. **Sync Versions**: Automatically synchronizes version information (see Version Management below)
5. **Update README**: Automatically updates API Endpoints and Models sections in README.md
6. **Verify**: Checks that the generated code is valid
7. **Report**: Shows a summary and next steps

## Version Management (Automatic)

### How Version Synchronization Works

The update script **automatically manages version information** to prevent overwrites:

**Problem**: OpenAPI Generator regenerates `orbuculum_client/__init__.py`, which would overwrite version constants.

**Solution**: After code generation, the script automatically:
1. Reads **client version** from `pyproject.toml` (protected file)
2. Extracts **API version** from the downloaded OpenAPI spec
3. Updates `orbuculum_client/__init__.py` with correct values:
   ```python
   __version__ = "0.0.1"          # From pyproject.toml
   __api_version__ = "0.4.0"      # From OpenAPI spec
   __api_supported__ = "0.4.0"    # From OpenAPI spec
   ```

### Single Source of Truth

- **Client version**: Managed in `pyproject.toml` only
- **API version**: Extracted from OpenAPI spec automatically
- **No manual synchronization needed**

### Workflow

1. **Run updater**:
   ```bash
   docker-compose run --rm updater
   ```
   Versions are automatically synced ✨

2. **For new client release**, update only `pyproject.toml`:
   ```toml
   version = "0.0.2"  # Bump according to SemVer
   ```
   Next update will sync it to `__init__.py`

3. **Verify synchronization**:
   ```bash
   grep -A2 '__version__' orbuculum_client/__init__.py
   grep '^version' pyproject.toml
   ```

See [VERSIONING.md](VERSIONING.md) for version bump guidelines.

### After Running the Update

After the automatic update completes, you should:

1. **Review Changes**:
   ```bash
   git diff
   ```

2. **Check Version Sync** (automatic, but verify):
   ```bash
   # Client version from pyproject.toml
   grep '^version' pyproject.toml
   
   # Should match __version__ in __init__.py
   grep '__version__' orbuculum_client/__init__.py
   
   # API version should be updated from spec
   grep '__api_version__' orbuculum_client/__init__.py
   ```

3. **Update Client Version** (only if releasing new version):
   ```toml
   # pyproject.toml
   version = "0.0.2"  # Bump according to change type
   ```
   
   See [VERSIONING.md](VERSIONING.md) for complete guidelines.

4. **Test the Client**:
   ```bash
   docker-compose run --rm dev pytest
   ```

5. **Build Package**:
   ```bash
   docker-compose run --rm builder
   ```

6. **Commit Changes**:
   ```bash
   git add .
   git commit -m "Update to API 0.4.0 (client version 0.0.1)"
   git push
   ```

## Manual Update (Without Docker)

> ⚠️ **Warning**: Manual updates are not recommended. The Docker method ensures correct tool versions and dependencies.

If you prefer to update manually or Docker is not available:

### Prerequisites

- **Java 11 or higher** (required for OpenAPI Generator)
- **OpenAPI Generator CLI 7.15.0** (exact version required)
- **Python 3.9+** (3.13 recommended)
- **Critical dependencies**:
  - `lazy-imports>=1,<2` - Required for module loading
  - `pydantic>=2` - Required for data validation
  - `typing-extensions>=4.7.1` - Required for type hints
  - `urllib3>=2.1.0,<3.0.0` - HTTP client library

### Install OpenAPI Generator

Download the JAR file:
```bash
curl -L https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.15.0/openapi-generator-cli-7.15.0.jar \
  -o openapi-generator-cli.jar
```

### Manual Update Steps

1. **Download the OpenAPI specification**:
   ```bash
   curl -o orbuculum-openapi.json https://s1.orbuculum.app/swagger/json
   ```

2. **Backup existing code**:
   ```bash
   cp -r orbuculum orbuculum.backup
   cp -r docs docs.backup
   ```

3. **Install dependencies**:
   ```bash
   pip install 'lazy-imports>=1,<2' 'pydantic>=2' 'typing-extensions>=4.7.1' 'urllib3>=2.1.0,<3.0.0'
   ```

4. **Run OpenAPI Generator**:
   ```bash
   java -jar openapi-generator-cli.jar generate \
     -i orbuculum-openapi.json \
     -g python \
     -o . \
     --package-name orbuculum_client \
     --library urllib3
   ```

   > **Note**: The `--library urllib3` parameter is critical - it specifies the HTTP client library used for API calls.

5. **Verify the generated code**:
   ```bash
   python3 -c "import orbuculum_client; print(orbuculum_client.__version__)"
   ```

6. **Run tests**:
   ```bash
   pytest
   ```

## Checking for API Updates

To check if the API has been updated, compare the version in the spec with your current version:

```bash
# Get current version
grep "version" pyproject.toml | head -1

# Get API version
curl -s https://s1.orbuculum.app/swagger/json | grep -o '"version":"[^"]*"'
```

## What Gets Regenerated

When you update, the following files are regenerated:

- `orbuculum/` - All Python client code
- `docs/` - API documentation
- `.openapi-generator/` - Generator metadata

**Protected files** (listed in `.openapi-generator-ignore`):
- `pyproject.toml` - Version and project configuration (NEVER overwritten)
- `README.md` - Main documentation (NEVER fully overwritten)

**Regenerated but auto-corrected**:
- `orbuculum_client/__init__.py` - Regenerated, then version info is automatically synced from `pyproject.toml`
- `README.md` - Only API Endpoints and Models sections are auto-updated, rest is preserved

**Automatic backup**: The update script (`scripts/update_api.sh`) automatically creates a timestamped backup in `backups/backup_YYYYMMDD_HHMMSS/` before regenerating code.

**Note**: Any manual changes to generated files (except version info and README structure) will be lost. If you need custom modifications, maintain them separately or use inheritance/composition patterns.

## Troubleshooting

### Update Script Fails

If the automatic update fails, a backup is created automatically. To restore:

```bash
# The script will show the backup location, e.g.:
rm -rf orbuculum
cp -r /workspace/backup_20251006_152345/orbuculum .
```

### Import Errors After Update

If imports fail after updating:

1. Check that dependencies are installed:
   ```bash
   pip install -r requirements.txt
   ```

2. Verify Python version compatibility (requires Python 3.8+)

3. Try reinstalling in development mode:
   ```bash
   pip install -e .
   ```

### Version Mismatch

If you see a version mismatch error:

**This should not happen** - versions are synced automatically. If it does:

1. **Re-run the updater**:
   ```bash
   docker-compose run --rm updater
   ```
   The sync script will fix the mismatch.

2. **Check pyproject.toml format**:
   ```toml
   # Must be on its own line, exactly like this:
   version = "0.0.1"
   ```

3. **Manual fix** (if updater fails):
   ```bash
   # Get version from pyproject.toml
   CLIENT_VERSION=$(grep -m1 '^version = ' pyproject.toml | cut -d'"' -f2)
   
   # Update __init__.py manually
   sed -i "s/__version__ = \".*\"/__version__ = \"${CLIENT_VERSION}\"/" orbuculum_client/__init__.py
   ```

> See [VERSIONING.md](VERSIONING.md) for version update rules.

## Breaking Changes

When the API introduces breaking changes:

1. Check the [API changelog](https://s1.orbuculum.app/swagger) for breaking changes
2. Update `__api_supported__` in `orbuculum_client/__init__.py`
3. Determine if client needs a MAJOR version bump:
   - Breaking change in client code → bump MAJOR (e.g., 1.x.x → 2.0.0)
   - Only API schema changed → bump MINOR (e.g., 1.1.x → 1.2.0)
4. Update your code that uses the client
5. Run comprehensive tests before deploying

See [VERSIONING.md](VERSIONING.md) for detailed version bump rules.

## Automation in CI/CD

To automate API updates in your CI/CD pipeline:

```yaml
# Example GitHub Actions workflow
name: Check API Updates
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

jobs:
  check-updates:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run updater
        run: docker-compose run --rm updater
      - name: Create PR if changes
        # Add your PR creation logic here
```

## Additional Resources

- **API Documentation**: https://s1.orbuculum.app/swagger
- **OpenAPI Generator**: https://openapi-generator.tech
- **Docker Setup**: See [DOCKER.md](DOCKER.md)
- **Version Management**: See [VERSIONING.md](VERSIONING.md)
- **Publishing**: See [PUBLISHING.md](PUBLISHING.md)

## Technical Details

For in-depth information about how version synchronization works:
- See `dev-notes/VERSION_SYNC.md` for implementation details
- See `scripts/update_api.sh` (Step 3.5) for the sync script

## Questions?

If you encounter issues with the update process, please [open an issue](https://github.com/orbuculum-app/orbuculum-python-client/issues).
