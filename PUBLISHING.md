# Publishing Guide

This document describes how to publish the Orbuculum Python client to PyPI and TestPyPI.

> **💡 Quick Reference**: For a condensed version, see [QUICK_PUBLISH_GUIDE.md](QUICK_PUBLISH_GUIDE.md)

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Configuration](#configuration)
5. [Publishing Workflow](#publishing-workflow)
6. [Version Management](#version-management)
7. [Manual Publishing](#manual-publishing)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Overview

The Orbuculum Python client uses an automated publishing workflow that:
- ✅ Validates version consistency across files
- ✅ Runs tests before publishing
- ✅ Builds wheel and source distributions
- ✅ Uploads to PyPI or TestPyPI
- ✅ Creates and pushes git tags
- ✅ Provides safety checks and confirmations

All publishing is done in a **Docker container** to ensure a consistent, reproducible environment.

## Prerequisites

### Required Tools

1. **Docker** - For containerized builds
   ```bash
   docker --version  # Should show Docker 20.0+
   ```

2. **Docker Compose** - For managing services
   ```bash
   docker-compose --version
   ```

3. **PyPI Account** - Create accounts on:
   - Production: https://pypi.org/account/register/
   - Testing: https://test.pypi.org/account/register/

### API Token Setup

You need API tokens to publish packages. **Never use your password** - always use API tokens.

#### Create API Tokens

1. **For PyPI (production)**:
   - Go to https://pypi.org/manage/account/token/
   - Click "Add API token"
   - Name: `orbuculum-client`
   - Scope: Choose project `orbuculum` (or "Entire account" for first upload)
   - Copy the token (starts with `pypi-...`)

2. **For TestPyPI (testing)**:
   - Go to https://test.pypi.org/manage/account/token/
   - Follow same steps as above

#### Configure Tokens

Create or edit `~/.pypirc` on your machine:

```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = pypi-AgEIcHlwaS5vcmcC...  # Your PyPI token

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-AgENdGVzdC5weXBpLm9yZ...  # Your TestPyPI token
```

**Security notes**:
- File permissions: `chmod 600 ~/.pypirc` (user read/write only)
- The Docker container mounts this file as **read-only** (`:ro` flag)
- **NEVER** commit this file to git
- Tokens are valid until manually revoked
- Store backup of tokens in a secure password manager

## Quick Start

### Test Publishing (Recommended First)

Always test on TestPyPI before publishing to production PyPI:

```bash
# Publish to TestPyPI
docker-compose run --rm publisher testpypi

# Test installation
pip install -i https://test.pypi.org/simple/ orbuculum-client==1.0.0
```

> **Note:** Git operations (tagging) are **automatically disabled** for TestPyPI since it's a testing environment. This allows you to test the publishing process multiple times without creating git tags.

### Production Publishing

Once tested, publish to production PyPI:

```bash
# Publish to PyPI
docker-compose run --rm publisher pypi

# Test installation
pip install orbuculum-client==1.0.0
```

> **Note:** For **PyPI** (production), the script will create a git tag (e.g., `v1.0.0`) and ask if you want to push it to the remote repository.

## Configuration

### Version Configuration

Version must be consistent across three locations:

1. **`pyproject.toml`**:
   ```toml
   [project]
   version = "1.0.0"  # Client version (independent)
   ```

2. **`orbuculum_client/__init__.py`**:
   ```python
   __version__ = "1.0.0"         # Client version
   __api_version__ = "0.4.0"     # API version
   __api_supported__ = "0.4.0"   # Supported API
   ```

3. **Git tag**: `v1.0.0`

The publishing script **automatically validates** version consistency before publishing.

> **Note:** Starting from v1.0.0, the client version is **independent** from the API version. See [VERSIONING.md](VERSIONING.md) for details.

### Docker Configuration

The `publisher` service is configured in `docker-compose.yml`:

```yaml
publisher:
  build:
    context: ./docker
    dockerfile: Dockerfile
  container_name: orbuculum-publisher
  volumes:
    - .:/workspace                    # Project files
    - ~/.pypirc:/root/.pypirc:ro      # PyPI credentials (read-only mount)
  working_dir: /workspace
  stdin_open: true
  tty: true
  entrypoint: /workspace/scripts/publish.sh
```

**Security features**:
- Credentials file is mounted as **read-only** (`:ro`)
- Container cannot modify or leak credentials
- All operations run in isolated Docker environment
- Build artifacts are created with proper permissions

## Publishing Workflow

### Standard Workflow

The automated publishing process follows these steps:

1. **Version Extraction & Validation**
   - Extracts version from `pyproject.toml`
   - Validates consistency with `orbuculum/__init__.py`

2. **Git Status Check**
   - Ensures working directory is clean (no uncommitted changes)
   - Checks if git tag already exists

3. **Run Tests**
   - Runs pytest to ensure code quality
   - Can be skipped with `--skip-tests`

4. **Clean & Build**
   - Removes old build artifacts
   - Builds wheel (`.whl`) and source distribution (`.tar.gz`)

5. **Upload Confirmation**
   - Shows package details
   - Asks for confirmation before upload

6. **Upload to PyPI/TestPyPI**
   - Uses `twine` to upload packages
   - Validates package before upload

7. **Git Tagging**
   - Creates annotated git tag (`v{version}`)
   - Optionally pushes tag to remote

8. **Success Summary**
   - Shows installation commands
   - Provides verification steps

### Command Options

```bash
# Basic usage
docker-compose run --rm publisher [pypi|testpypi] [OPTIONS]

# Available options:
--dry-run       # Show what would be done without doing it
--no-git        # Skip git operations (automatic for testpypi)
--skip-tests    # Skip running tests
--skip-build    # Use existing dist/ (for re-uploading)
--help          # Show help message
```

> **Important:** Git operations (tagging) are **automatically disabled** for `testpypi` target. The `--no-git` flag is only needed if you want to skip git operations when publishing to production `pypi`.

### Usage Examples

```bash
# Standard publish to TestPyPI (git operations auto-disabled)
docker-compose run --rm publisher testpypi

# Dry run to see what would happen
docker-compose run --rm publisher pypi --dry-run

# Publish to PyPI without git operations (if needed)
docker-compose run --rm publisher pypi --no-git

# Skip tests (if already run)
docker-compose run --rm publisher pypi --skip-tests

# Re-upload existing build
docker-compose run --rm publisher pypi --skip-build
```

## Version Management

### Semantic Versioning

We follow [Semantic Versioning](https://semver.org/) (SemVer) for the **client version**:

- **MAJOR** version: Breaking changes in client library (`1.0.0` → `2.0.0`)
- **MINOR** version: New features, backward-compatible (`1.0.0` → `1.1.0`)
- **PATCH** version: Bug fixes, no API changes (`1.0.0` → `1.0.1`)

> **Important:** The client version is **decoupled** from the API version. A client update doesn't require an API update and vice versa. See [VERSIONING.md](VERSIONING.md) for complete guidelines.

### How to Bump Version

When you're ready to release a new version:

1. **Update `pyproject.toml`**:
   ```toml
   [project]
   version = "1.1.0"  # Updated client version
   ```

2. **Update `orbuculum_client/__init__.py`**:
   ```python
   __version__ = "1.1.0"
   __api_version__ = "0.4.0"       # Update if API changed
   __api_supported__ = "0.4.0"     # Update if API changed
   ```

3. **Commit the changes**:
   ```bash
   git add pyproject.toml orbuculum_client/__init__.py
   git commit -m "Release 1.1.0 - Supports API 0.4.0"
   git push
   ```

4. **Publish**:
   ```bash
   docker-compose run --rm publisher testpypi  # Test first
   docker-compose run --rm publisher pypi      # Then production
   ```

The git tag (`v1.1.0`) will be created automatically by the script.

> **When to update API version:** Only update `__api_version__` and `__api_supported__` when the underlying API schema changes. Client-only improvements keep API version unchanged.

### Pre-release Versions

For alpha, beta, or release candidate versions:

```toml
version = "1.1.0a1"   # Alpha
version = "1.1.0b2"   # Beta
version = "1.1.0rc3"  # Release Candidate
```

### Version Update Examples

**Scenario 1: Bug fix, no API change**
```python
# pyproject.toml: 1.0.0 → 1.0.1
# __init__.py
__version__ = "1.0.1"
__api_supported__ = "0.4.0"  # Unchanged
```

**Scenario 2: New feature + API update**
```python
# pyproject.toml: 1.0.1 → 1.1.0
# __init__.py
__version__ = "1.1.0"
__api_supported__ = "0.5.0"  # Updated
```

**Scenario 3: Breaking change**
```python
# pyproject.toml: 1.1.0 → 2.0.0
# __init__.py
__version__ = "2.0.0"
__api_supported__ = "1.0.0"  # May also change
```

## Manual Publishing

If you need to publish manually without Docker:

### 1. Install Tools

```bash
pip install --upgrade build twine
```

### 2. Build Package

```bash
python -m build --wheel --sdist --outdir dist/
```

### 3. Check Package

```bash
twine check dist/*
```

### 4. Upload

```bash
# For TestPyPI
twine upload --repository testpypi dist/*

# For PyPI
twine upload --repository pypi dist/*
```

### 5. Create Git Tag

```bash
git tag -a v1.0.0 -m "Release 1.0.0 - Supports API 0.4.0"
git push origin v1.0.0
```

## Troubleshooting

### Common Issues

#### 1. "Version already exists on PyPI"

**Error**: `File already exists`

**Solution**: You cannot overwrite an existing version on PyPI. You must bump the version:
```bash
# Update version in pyproject.toml and __init__.py
# Then publish the new version
```

**Prevention**: Always check the current published version before building.

#### 2. "Git working directory has uncommitted changes"

**Error**: `Git working directory has uncommitted changes`

**Solution**: 
```bash
# Option 1: Commit changes
git add .
git commit -m "Your commit message"

# Option 2: Stash changes
git stash

# Option 3: Skip git checks
docker-compose run --rm publisher pypi --no-git
```

#### 3. "Version mismatch between files"

**Error**: `Version mismatch! pyproject.toml: 1.0.0, __init__.py: 0.4.0`

**Solution**: Update both files to have the same client version:
```bash
# Edit pyproject.toml and orbuculum_client/__init__.py
# Ensure __version__ matches version in pyproject.toml
# Note: __api_version__ is separate and doesn't need to match
```

#### 4. "No credentials configured"

**Error**: `Upload failed - 403 Forbidden`

**Solution**: Configure your `~/.pypirc` file (see [Configuration](#configuration))

#### 5. "Tests failing"

**Error**: `Tests failed`

**Solution**:
```bash
# Run tests locally to see what's wrong
docker-compose run --rm dev pytest

# Fix the issues, or skip tests (not recommended)
docker-compose run --rm publisher pypi --skip-tests
```

#### 6. "Docker permission denied"

**Error**: `Permission denied while trying to connect to Docker daemon`

**Solution**:
```bash
# Option 1: Run with sudo (not recommended)
sudo docker-compose run --rm publisher pypi

# Option 2: Add user to docker group (recommended)
sudo usermod -aG docker $USER
# Then log out and back in
```

#### 7. "Package name conflicts"

**Error**: `The name 'orbuculum-client' is too similar to existing package`

**Solution**: Package name is already registered. This shouldn't happen for updates, only initial registration.

### Validation Commands

Before publishing, you can validate your setup:

```bash
# Check Docker is working
docker --version
docker-compose --version

# Check files exist
ls -la ~/.pypirc

# Check version consistency
grep version pyproject.toml
grep __version__ orbuculum_client/__init__.py

# Build and check (without uploading)
docker-compose run --rm builder
twine check dist/*

# Dry run
docker-compose run --rm publisher pypi --dry-run
```

### Getting Help

If you encounter issues not covered here:

1. Check the [GitHub Issues](https://github.com/yourusername/orbuculum-python-client/issues)
2. Review PyPI documentation: https://packaging.python.org/
3. Check twine documentation: https://twine.readthedocs.io/

## Best Practices

### Before Publishing

- ✅ **Test thoroughly** - Run all tests locally
- ✅ **Test on TestPyPI first** - Always test before production
- ✅ **Update changelog** - Document what changed
- ✅ **Review version** - Ensure it follows SemVer
- ✅ **Clean git state** - Commit all changes
- ✅ **Update documentation** - Keep README up to date

### During Publishing

- ✅ **Use dry-run** - Preview changes before real upload
- ✅ **Double-check version** - Verify it's correct
- ✅ **Monitor upload** - Watch for errors
- ✅ **Test installation immediately** - Verify package works

### After Publishing

- ✅ **Test installation** - Install and verify package works
- ✅ **Check package page** - Verify metadata is correct
- ✅ **Push git tags** - Ensure tags are on remote
- ✅ **Update GitHub release** - Create release notes
- ✅ **Announce release** - Notify users of new version

### Security Best Practices

- 🔒 **Never commit credentials** - Use `.pypirc`, not environment variables in code
- 🔒 **Use API tokens** - Not passwords
- 🔒 **Limit token scope** - Use project-specific tokens when possible
- 🔒 **Rotate tokens periodically** - Update tokens every 6-12 months
- 🔒 **Use 2FA** - Enable two-factor authentication on PyPI
- 🔒 **Review uploads** - Check what's included in distributions

### Automation Tips

For CI/CD automation:

1. **Store tokens as secrets** - Use GitHub Secrets or similar
2. **Use GitHub Actions** - Automate publishing on release
3. **Require manual approval** - Don't auto-publish on every commit
4. **Test in CI** - Run tests before publishing

Example GitHub Action snippet:
```yaml
- name: Publish to PyPI
  env:
    TWINE_USERNAME: __token__
    TWINE_PASSWORD: ${{ secrets.PYPI_API_TOKEN }}
  run: |
    python -m build
    twine upload dist/*
```

---

## Summary

**For most users**, the publishing process is simple:

```bash
# 1. Update version in pyproject.toml and __init__.py
# 2. Commit changes
# 3. Test on TestPyPI
docker-compose run --rm publisher testpypi

# 4. Publish to PyPI
docker-compose run --rm publisher pypi

# 5. Verify installation
pip install orbuculum-client==<version>
```

That's it! The script handles all the complexity for you.

For questions or issues, please open a GitHub issue.
