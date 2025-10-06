# Quick Publishing Guide

**TL;DR** - One command to publish: `docker-compose run --rm publisher [pypi|testpypi]`

## Prerequisites (One-time Setup)

1. **Configure PyPI credentials** in `~/.pypirc`:
```ini
[pypi]
username = __token__
password = pypi-YOUR_TOKEN_HERE

[testpypi]
repository = https://test.pypi.org/legacy/
username = __token__
password = pypi-YOUR_TESTPYPI_TOKEN_HERE
```

2. **Set file permissions**:
```bash
chmod 600 ~/.pypirc
```

## Publishing Workflow

### 1. Update Version

Edit version in two locations:

**`pyproject.toml`:**
```toml
version = "1.X.0"  # Client version
```

**`orbuculum_client/__init__.py`:**
```python
__version__ = "1.X.0"         # Client version (must match pyproject.toml)
__api_supported__ = "0.4.0"   # Update only if API changed
```

> **Note:** Client version is independent from API version. See [VERSIONING.md](VERSIONING.md).

Commit:
```bash
git add pyproject.toml orbuculum_client/__init__.py
git commit -m "Release 1.X.0 - Supports API 0.4.0"
git push
```

### 2. Test on TestPyPI (ALWAYS DO THIS FIRST!)

```bash
docker-compose run --rm publisher testpypi
```

> **Note:** Git operations (tagging) are automatically disabled for TestPyPI since it's a testing environment.

Verify:
```bash
pip install -i https://test.pypi.org/simple/ orbuculum-client==1.X.0
python -c "import orbuculum_client; print(f'Client: {orbuculum_client.__version__}, API: {orbuculum_client.__api_supported__}')"
```

### 3. Publish to Production PyPI

```bash
docker-compose run --rm publisher pypi
```

Verify:
```bash
pip install --upgrade orbuculum-client
python -c "import orbuculum_client; print(f'Client: {orbuculum_client.__version__}, API: {orbuculum_client.__api_supported__}')"
```

## Common Commands

```bash
# Dry run (preview without uploading)
docker-compose run --rm publisher pypi --dry-run

# Skip tests (if already run)
docker-compose run --rm publisher pypi --skip-tests

# Skip git operations (for PyPI; automatic for TestPyPI)
docker-compose run --rm publisher pypi --no-git

# Re-upload existing build
docker-compose run --rm publisher pypi --skip-build

# Show all options
docker-compose run --rm publisher pypi --help
```

> **Note:** When publishing to **TestPyPI**, git operations are **automatically disabled** since it's a testing environment. For **PyPI** (production), git tags are created by default.

## Troubleshooting

### "Version already exists"
→ You need to bump the version number. PyPI doesn't allow re-uploading.

### "Git working directory has uncommitted changes"
→ Commit your changes: `git add . && git commit -m "..."`

### "Version mismatch"
→ Ensure `__version__` in `__init__.py` matches `version` in `pyproject.toml`
→ Note: `__api_version__` is separate and doesn't need to match

### "No credentials"
→ Configure `~/.pypirc` (see Prerequisites above)

## Full Documentation

For complete documentation, see [PUBLISHING.md](PUBLISHING.md)

## Safety Features

The script automatically:
- ✅ Validates version consistency
- ✅ Checks git status (clean working directory)
- ✅ Runs tests
- ✅ Asks for confirmation before upload
- ✅ Creates git tags
- ✅ Provides rollback on failure

## Architecture

```
User → docker-compose → Docker Container → scripts/publish.sh
                                        ↓
                                   [Validation]
                                        ↓
                                   [Build]
                                        ↓
                                   [Upload via twine]
                                        ↓
                                   [Git Tag]
```

## Technical Environment

The Docker container includes:
- **Python**: 3.13-slim
- **Build tools**: pip, setuptools, wheel, build, twine (latest stable)
- **OpenAPI Generator**: 7.15.0
- **Pre-installed dependencies**: All required packages

This ensures:
- ✅ Reproducible builds across all machines
- ✅ Correct tool versions
- ✅ No host system conflicts
- ✅ Secure credential handling (read-only mount)

---

**Remember**: Always test on TestPyPI first! 🚀
