# Update and Publish Guide

Complete guide for updating the Orbuculum Python client and publishing to PyPI.

## Quick Reference

### API Update Process
```bash
# 1. Update API client from latest spec
# Script will ask about version and run tests automatically
docker-compose run --rm updater

# Or from custom URL (staging, dev, local):
# docker-compose run --rm updater -u https://dev.orbuculum.app/swagger/json

# Skip tests (faster, for quick iterations):
# docker-compose run --rm updater --skip-tests

# Keep version + skip tests (no prompts):
# docker-compose run --rm updater -k -s

# 2. Review changes
git diff

# 3. Commit (tests already passed!)
git add .
git commit -m "Update to API 0.X.0"  # or "Release 1.X.0 - Supports API 0.Y.0"
git push
```

### Publishing Process
```bash
# 1. Update version using the updater script (if not done already)
docker-compose run --rm updater
# → Choose option [2-5] to bump version

# 2. Test on TestPyPI
docker-compose run --rm publisher testpypi

# 3. Publish to PyPI (creates git tag v1.X.0 automatically)
docker-compose run --rm publisher pypi

# 4. Push git tag to GitHub
git push origin v1.X.0
```

### Combined Workflow (API Update + Publish)
```bash
# 1. Update API client and bump version interactively
docker-compose run --rm updater
# → Script shows current client version and new API version
# → Asks: Keep current, patch/minor/major bump, or manual version?
# → Automatically updates pyproject.toml and orbuculum_client/__init__.py

# 2. Test
docker-compose run --rm dev pytest

# 3. Commit
git add .
git commit -m "Release 1.X.0 - Supports API 0.Y.0"
git push

# 4. Test publish
docker-compose run --rm publisher testpypi

# 5. Production publish (creates git tag v1.X.0 automatically)
docker-compose run --rm publisher pypi

# 6. Push git tag to GitHub
git push origin v1.X.0
```

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [API Updates](#api-updates)
3. [Version Management](#version-management)
4. [Publishing](#publishing)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)

---

## Prerequisites

### One-Time Setup

#### 1. Docker
```bash
docker --version  # Should show Docker 20.0+
docker-compose --version
```

#### 2. PyPI Credentials

Create `~/.pypirc`:
```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-YOUR_TOKEN_HERE

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-YOUR_TESTPYPI_TOKEN_HERE
```

Set permissions:
```bash
chmod 600 ~/.pypirc
```

Get tokens:
- **PyPI**: https://pypi.org/manage/account/token/
- **TestPyPI**: https://test.pypi.org/manage/account/token/

---

## API Updates

### Overview

The client is automatically generated from the [OpenAPI specification](https://s1.orbuculum.app/swagger/json) using OpenAPI Generator 7.15.0.

### Automatic Update (Recommended)

```bash
# Update from default production API
docker-compose run --rm updater

# Update from custom URL (e.g., staging, dev, local)
docker-compose run --rm updater --spec-url https://dev.orbuculum.app/swagger/json

# Short form (local server on host machine)
docker-compose run --rm updater -u http://host.docker.internal:8080/openapi.json
```

This command:
1. Downloads latest OpenAPI spec from specified URL (default: `https://s1.orbuculum.app/swagger/json`)
2. Creates automatic backup in `backups/backup_YYYYMMDD_HHMMSS/`
3. Regenerates client code
4. **Asks interactively** if you want to update client version:
   - Shows current client version and new API version
   - Offers options: keep current, patch/minor/major bump, or manual entry
   - Automatically updates both `pyproject.toml` and `orbuculum_client/__init__.py`
5. Updates README.md (API Endpoints and Models sections)
6. Verifies generated code
7. **Runs tests automatically** (can be skipped with `--skip-tests`)

#### Usage Examples

```bash
# Standard update (interactive version prompt, runs tests)
docker-compose run --rm updater

# Skip tests for faster iteration
docker-compose run --rm updater --skip-tests

# Keep version, run tests
docker-compose run --rm updater --keep-version

# Keep version, skip tests (fastest, for quick checks)
docker-compose run --rm updater -k -s

# Custom URL examples
docker-compose run --rm updater --spec-url https://staging.orbuculum.app/swagger/json
docker-compose run --rm updater -u https://dev.orbuculum.app/swagger/json

# Local development server (from host machine)
docker-compose run --rm updater -u http://host.docker.internal:3000/openapi.json
docker-compose run --rm updater -u http://host.docker.internal:8081/swagger/json

# Combination: custom URL, keep version, skip tests
docker-compose run --rm updater -k -s -u http://host.docker.internal:8081/swagger/json

# Local file (if mounted in Docker)
docker-compose run --rm updater -u file:///workspace/custom-spec.json
```

> **Note:** Use `host.docker.internal` instead of `localhost` to access services running on your host machine from inside Docker containers. This works on all platforms (macOS, Windows, Linux).

### What Gets Regenerated

**Regenerated files:**
- `orbuculum_client/` - All Python client code
- `docs/` - API documentation
- `.openapi-generator/` - Generator metadata

**Protected files** (never overwritten):
- `pyproject.toml` - Version and project configuration
- `README.md` - Main documentation (only API sections updated)

**Auto-corrected files:**
- `orbuculum_client/__init__.py` - Regenerated, then versions synced from `pyproject.toml`

### Interactive Version Management

The update script includes **interactive version management**:

#### During Update

When you run `docker-compose run --rm updater`, the script will:

1. **Show current versions:**
   ```
   Current client version: 1.0.0
   API version from spec: 0.5.0
   ```

2. **Ask what to do:**
   ```
   Do you want to update the client version?
     [1] Keep current version (1.0.0)
     [2] Patch bump (1.0.1) - Bug fixes
     [3] Minor bump (1.1.0) - New features, backward-compatible
     [4] Major bump (2.0.0) - Breaking changes
     [5] Enter version manually
   
   Choose option [1-5]:
   ```

3. **Automatically update both files:**
   - Updates `pyproject.toml` with new version
   - Updates `orbuculum_client/__init__.py` with new client version
   - Updates `__api_version__` and `__api_supported__` with new API version

#### When to Bump Version

- **Keep current (1)**: API update only, no client changes
- **Patch (2)**: Bug fixes in client code
- **Minor (3)**: New API features added, backward-compatible
- **Major (4)**: Breaking changes in API or client
- **Manual (5)**: Pre-release versions (1.1.0a1, 1.1.0b2, 1.1.0rc1)

**No manual file editing needed!** The script handles everything.

### After Update

```bash
# 1. Review changes
git diff

# 2. Verify versions
grep '^version' pyproject.toml
grep '__version__' orbuculum_client/__init__.py
grep '__api_version__' orbuculum_client/__init__.py

# 3. Test
docker-compose run --rm dev pytest

# 4. Commit
git add .
git commit -m "Update to API 0.X.0 (client version 1.Y.Z)"
git push
```

### Manual Update (Not Recommended)

If Docker is unavailable:

#### Prerequisites
- Java 11+ (for OpenAPI Generator)
- OpenAPI Generator CLI 7.15.0
- Python 3.9+

#### Steps
```bash
# Download spec
curl -o orbuculum-openapi.json https://s1.orbuculum.app/swagger/json

# Backup
cp -r orbuculum_client orbuculum_client.backup

# Generate
java -jar openapi-generator-cli.jar generate \
  -i orbuculum-openapi.json \
  -g python \
  -o . \
  --package-name orbuculum_client \
  --library urllib3

# Test
python3 -c "import orbuculum_client; print(orbuculum_client.__version__)"
pytest
```

### Checking for API Updates

```bash
# Current client version
grep '^version' pyproject.toml

# Current API version
grep '__api_version__' orbuculum_client/__init__.py

# Latest API version
curl -s https://s1.orbuculum.app/swagger/json | grep -o '"version":"[^"]*"'
```

---

## Version Management

### Semantic Versioning

**Client version** (independent from API):
- **MAJOR**: Breaking changes in client (`1.0.0` → `2.0.0`)
- **MINOR**: New features, backward-compatible (`1.0.0` → `1.1.0`)
- **PATCH**: Bug fixes (`1.0.0` → `1.0.1`)

**API version** (tracked separately):
- Extracted from OpenAPI spec automatically
- Updated only when API changes

### Version Files

Version must be consistent across:

1. **`pyproject.toml`** (source of truth):
   ```toml
   [project]
   version = "1.0.0"  # Client version
   ```

2. **`orbuculum_client/__init__.py`** (synced automatically):
   ```python
   __version__ = "1.0.0"         # Client version (matches pyproject.toml)
   __api_version__ = "0.4.0"     # API version (from spec)
   __api_supported__ = "0.4.0"   # Supported API
   ```

3. **Git tag**: `v1.0.0` (created automatically when publishing)

### Bumping Version

When ready to release:

```bash
# 1. Update pyproject.toml
# Edit: version = "1.1.0"

# 2. Update orbuculum_client/__init__.py
# Edit: __version__ = "1.1.0"
# Update __api_supported__ only if API changed

# 3. Re-run updater to sync (optional but recommended)
docker-compose run --rm updater

# 4. Commit
git add pyproject.toml orbuculum_client/__init__.py
git commit -m "Release 1.1.0 - Supports API 0.4.0"
git push
```

### Version Update Scenarios

**Bug fix, no API change:**
```python
# pyproject.toml: 1.0.0 → 1.0.1
__version__ = "1.0.1"
__api_supported__ = "0.4.0"  # Unchanged
```

**New feature + API update:**
```python
# pyproject.toml: 1.0.1 → 1.1.0
__version__ = "1.1.0"
__api_supported__ = "0.5.0"  # Updated
```

**Breaking change:**
```python
# pyproject.toml: 1.1.0 → 2.0.0
__version__ = "2.0.0"
__api_supported__ = "1.0.0"  # May also change
```

### Pre-release Versions

```toml
version = "1.1.0a1"   # Alpha
version = "1.1.0b2"   # Beta
version = "1.1.0rc3"  # Release Candidate
```

---

## Publishing

### Overview

Automated publishing workflow:
- ✅ Validates version consistency
- ✅ Runs tests
- ✅ Builds distributions
- ✅ Uploads to PyPI/TestPyPI
- ✅ Creates git tags
- ✅ Safety checks and confirmations

### Standard Workflow

#### 1. Test on TestPyPI (ALWAYS FIRST!)

```bash
docker-compose run --rm publisher testpypi
```

> **Note:** Git operations (tagging) are **automatically disabled** for TestPyPI.

Verify installation:
```bash
pip install -i https://test.pypi.org/simple/ orbuculum-client==1.X.0
python -c "import orbuculum_client; print(f'Client: {orbuculum_client.__version__}, API: {orbuculum_client.__api_supported__}')"
```

#### 2. Publish to Production PyPI

```bash
docker-compose run --rm publisher pypi
```

> **Note:** For PyPI, git tag `v1.X.0` is created automatically. Script asks if you want to push it.

Verify installation:
```bash
pip install --upgrade orbuculum-client
python -c "import orbuculum_client; print(f'Client: {orbuculum_client.__version__}, API: {orbuculum_client.__api_supported__}')"
```

### Publishing Process Steps

The script performs:

1. **Version Validation**
   - Extracts version from `pyproject.toml`
   - Validates consistency with `orbuculum_client/__init__.py`

2. **Git Status Check**
   - Ensures clean working directory
   - Checks if git tag already exists

3. **Run Tests**
   - Executes pytest
   - Can be skipped with `--skip-tests`

4. **Build**
   - Cleans old artifacts
   - Builds wheel (`.whl`) and source distribution (`.tar.gz`)

5. **Upload Confirmation**
   - Shows package details
   - Asks for confirmation

6. **Upload**
   - Uses `twine` to upload packages
   - Validates before upload

7. **Git Tagging**
   - Creates annotated tag `v{version}`
   - Optionally pushes to remote

8. **Success Summary**
   - Shows installation commands
   - Provides verification steps

### Command Options

```bash
# Basic usage
docker-compose run --rm publisher [pypi|testpypi] [OPTIONS]

# Available options:
--dry-run       # Preview without uploading
--no-git        # Skip git operations (auto for testpypi)
--skip-tests    # Skip running tests
--skip-build    # Use existing dist/
--help          # Show help
```

### Usage Examples

```bash
# Standard TestPyPI publish
docker-compose run --rm publisher testpypi

# Dry run
docker-compose run --rm publisher pypi --dry-run

# Skip tests (if already run)
docker-compose run --rm publisher pypi --skip-tests

# Skip git operations
docker-compose run --rm publisher pypi --no-git

# Re-upload existing build
docker-compose run --rm publisher pypi --skip-build
```

### Manual Publishing

If Docker is unavailable:

```bash
# Install tools
pip install --upgrade build twine

# Build
python -m build --wheel --sdist --outdir dist/

# Check
twine check dist/*

# Upload to TestPyPI
twine upload --repository testpypi dist/*

# Upload to PyPI
twine upload --repository pypi dist/*

# Create git tag
git tag -a v1.0.0 -m "Release 1.0.0 - Supports API 0.4.0"
git push origin v1.0.0
```

---

## Troubleshooting

### API Update Issues

#### Update Script Fails

Backup is created automatically. To restore:
```bash
# Script shows backup location, e.g.:
rm -rf orbuculum_client
cp -r backups/backup_20251106_152345/orbuculum_client .
```

#### Import Errors After Update

```bash
# Check dependencies
pip install -r requirements.txt

# Verify Python version
python --version  # Should be 3.8+

# Reinstall in dev mode
pip install -e .
```

#### Version Mismatch

Should not happen with automatic sync. If it does:

```bash
# Re-run updater
docker-compose run --rm updater

# Or manual fix
CLIENT_VERSION=$(grep -m1 '^version = ' pyproject.toml | cut -d'"' -f2)
sed -i "s/__version__ = \".*\"/__version__ = \"${CLIENT_VERSION}\"/" orbuculum_client/__init__.py
```

### Publishing Issues

#### "Version already exists on PyPI"

**Solution:** PyPI doesn't allow re-uploading. Bump version:
```bash
# Update pyproject.toml and __init__.py
# Then publish new version
```

#### "Git working directory has uncommitted changes"

**Solution:**
```bash
# Option 1: Commit
git add .
git commit -m "Your message"

# Option 2: Stash
git stash

# Option 3: Skip git checks
docker-compose run --rm publisher pypi --no-git
```

#### "Version mismatch between files"

**Error:** `Version mismatch! pyproject.toml: 1.0.0, __init__.py: 0.4.0`

**Solution:**
```bash
# Ensure __version__ in __init__.py matches version in pyproject.toml
# Note: __api_version__ is separate and doesn't need to match
```

#### "No credentials configured"

**Error:** `Upload failed - 403 Forbidden`

**Solution:** Configure `~/.pypirc` (see [Prerequisites](#prerequisites))

#### "Tests failing"

**Solution:**
```bash
# Run tests locally
docker-compose run --rm dev pytest

# Fix issues, or skip (not recommended)
docker-compose run --rm publisher pypi --skip-tests
```

#### "Docker permission denied"

**Solution:**
```bash
# Add user to docker group (recommended)
sudo usermod -aG docker $USER
# Log out and back in

# Or run with sudo (not recommended)
sudo docker-compose run --rm publisher pypi
```

### Validation Commands

```bash
# Check Docker
docker --version
docker-compose --version

# Check credentials
ls -la ~/.pypirc

# Check version consistency
grep '^version' pyproject.toml
grep '__version__' orbuculum_client/__init__.py
grep '__api_version__' orbuculum_client/__init__.py

# Build and check
docker-compose run --rm builder
twine check dist/*

# Dry run
docker-compose run --rm publisher pypi --dry-run
```

---

## Best Practices

### Before Publishing

- ✅ **Update API first** - Run updater if API changed
- ✅ **Test thoroughly** - Run all tests
- ✅ **Test on TestPyPI** - Always test before production
- ✅ **Update changelog** - Document changes
- ✅ **Review version** - Follow SemVer
- ✅ **Clean git state** - Commit all changes
- ✅ **Update documentation** - Keep README current

### During Publishing

- ✅ **Use dry-run** - Preview before upload
- ✅ **Double-check version** - Verify correctness
- ✅ **Monitor upload** - Watch for errors
- ✅ **Test immediately** - Verify package works

### After Publishing

- ✅ **Test installation** - Install and verify
- ✅ **Check package page** - Verify metadata
- ✅ **Push git tags** - Ensure tags on remote
- ✅ **Create GitHub release** - Add release notes
- ✅ **Announce release** - Notify users

### Security Best Practices

- 🔒 **Never commit credentials** - Use `.pypirc`
- 🔒 **Use API tokens** - Not passwords
- 🔒 **Limit token scope** - Project-specific when possible
- 🔒 **Rotate tokens** - Update every 6-12 months
- 🔒 **Enable 2FA** - On PyPI account
- 🔒 **Review uploads** - Check distribution contents

### Workflow Best Practices

**When API changes (no client release):**
```bash
docker-compose run --rm updater  # API update, choose [1] to keep version
docker-compose run --rm dev pytest  # Test
git commit -m "Update to API 0.X.0"  # Commit
git push
```

**When releasing new client version:**
```bash
docker-compose run --rm updater  # Choose [2-5] to bump version
docker-compose run --rm dev pytest  # Test
git commit -m "Release 1.X.0"  # Commit
git push
docker-compose run --rm publisher testpypi  # Test
docker-compose run --rm publisher pypi  # Publish
git push origin v1.X.0  # Push tag
```

**Combined (API update + client release):**
```bash
docker-compose run --rm updater
# → Script asks about version
# → Choose [2-4] for patch/minor/major bump, or [5] for manual
# → Script updates both files automatically
docker-compose run --rm dev pytest
git commit -m "Release 1.X.0 - Supports API 0.Y.0"
git push
docker-compose run --rm publisher testpypi
docker-compose run --rm publisher pypi
git push origin v1.X.0
```

---

## Additional Resources

- **API Documentation**: https://s1.orbuculum.app/swagger
- **OpenAPI Generator**: https://openapi-generator.tech
- **PyPI Packaging**: https://packaging.python.org/
- **Twine Documentation**: https://twine.readthedocs.io/
- **Docker Setup**: See [DOCKER.md](DOCKER.md)
- **Versioning Details**: See [VERSIONING.md](VERSIONING.md)

## Technical Details

For implementation details:
- `dev-notes/VERSION_SYNC.md` - Version synchronization
- `dev-notes/publishing-automation.md` - Publishing automation
- `scripts/update_api.sh` - Update script
- `scripts/publish.sh` - Publishing script

---

## Questions?

If you encounter issues, please [open an issue](https://github.com/orbuculum-app/orbuculum-python-client/issues).
