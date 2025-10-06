# Versioning Policy

This document describes the versioning strategy for the Orbuculum Python client.

## Independent Versioning

The client version is **decoupled** from the API version.

### Client Version (SemVer)

The client follows [Semantic Versioning 2.0.0](https://semver.org/):

```
MAJOR.MINOR.PATCH
```

#### When to bump versions:

- **MAJOR** - Breaking changes in the client library API
  - Removed or renamed public methods/classes
  - Changed function signatures
  - Incompatible behavior changes
  - Dropped support for Python versions

- **MINOR** - New features, backward-compatible
  - New API endpoints support
  - New helper methods
  - New optional parameters
  - Performance improvements

- **PATCH** - Bug fixes and small improvements
  - Bug fixes in existing functionality
  - Documentation updates
  - Internal refactoring without API changes
  - Dependency updates (minor/patch)

### API Version Tracking

The client maintains metadata about the supported API version:

```python
import orbuculum_client

print(orbuculum_client.__version__)        # Client version (e.g., "0.0.1")
print(orbuculum_client.__api_version__)    # Base API version (e.g., "0.4.0")
print(orbuculum_client.__api_supported__)  # Supported API version (e.g., "0.4.0")
```

## Version Update Guidelines

### Scenario 1: API Schema Unchanged

If you're releasing a client update **without API changes**:

```bash
# Bug fix or documentation update
0.0.1 → 0.0.2

# Keep __api_version__ and __api_supported__ unchanged
__api_version__ = "0.4.0"
__api_supported__ = "0.4.0"
```

### Scenario 2: API Schema Updated (Compatible)

New API endpoints or optional fields added:

```bash
# New feature (backward-compatible)
0.0.2 → 0.1.0

# Update API version tracking
__api_version__ = "0.5.0"      # New API version
__api_supported__ = "0.5.0"    # Now supports 0.5.0
```

### Scenario 3: API Breaking Changes

API introduces breaking changes:

```bash
# Breaking change in client
0.1.0 → 1.0.0

# Update API version
__api_version__ = "1.0.0"
__api_supported__ = "1.0.0"
```

### Scenario 4: Client Refactoring Only

Internal improvements, no API changes:

```bash
# Performance improvement or refactoring
0.1.0 → 0.2.0  (if significant new features)
0.0.1 → 0.0.2  (if minor fixes)

# API version stays the same
__api_version__ = "0.4.0"
__api_supported__ = "0.4.0"
```

## Release Process

> ⚠️ **Important**: All build and release operations must be performed using Docker. See [DOCKER.md](DOCKER.md) for details.

1. **Update version in `pyproject.toml`:**
   ```toml
   version = "0.1.0"  # Example: next minor version
   ```

2. **Update metadata in `orbuculum_client/__init__.py`:**
   ```python
   __version__ = "0.1.0"
   __api_version__ = "0.4.0"
   __api_supported__ = "0.4.0"
   ```

3. **Update README.md header:**
   ```markdown
   - **Client version:** 0.1.0
   - **Supports API version:** 0.4.0
   ```

4. **Build and verify the package:**
   ```bash
   docker-compose run --rm builder
   ls -lh dist/
   ```

5. **Tag the release:**
   ```bash
   git tag -a v0.1.0 -m "Release 0.1.0 - Supports API 0.4.0"
   git push origin v0.1.0
   ```

6. **Publish to PyPI:**
   ```bash
   docker-compose run --rm publisher
   ```

6. **Release notes format:**
   ```markdown
   # Release 0.1.0
   
   **Supports API:** 0.4.0
   
   ## Changes
   - Feature: Added new helper method for batch operations
   - Fix: Corrected pagination handling in list endpoints
   - Docs: Improved authentication examples
   ```

## Version History

| Client Version | Release Date | Supports API | Notes                                           |
|----------------|--------------|--------------|------------------------------------------------|
| 0.0.1          | 2025-10-06   | 0.4.0        | Initial release with new package name          |

## FAQs

**Q: How do I know which API version my client supports?**

```python
import orbuculum_client
print(orbuculum_client.__api_supported__)
```

**Q: Can I use client 0.1.0 with API 0.4.0?**

Yes, as long as `__api_supported__` indicates `0.4.0` or the client maintains backward compatibility.

**Q: What if the API version changes but the client doesn't need updates?**

The client version may stay the same or get a PATCH bump for documentation updates. The `__api_supported__` field will be updated to reflect the new tested API version.

**Q: Should I update the client if only the API changed?**

Only if:
- The API changes affect the generated code
- New endpoints/models were added
- Bug fixes are needed for API compatibility

Otherwise, the existing client continues to work with API version changes that don't affect the schema.

## Technical Environment

All version updates and builds must be performed in the standardized Docker environment:

### Build Environment
- **Python**: 3.13-slim (latest stable)
- **OpenAPI Generator**: 7.15.0 (locked version)
- **Build tools**: pip, setuptools, wheel, build, twine (latest stable)

### Code Generation
- **Generator library**: urllib3
- **Generator version**: OpenAPI Generator 7.15.0
- **Source**: https://s1.orbuculum.app/swagger/json

### Why Standardized Environment?
1. **Reproducibility**: Same results on all machines
2. **Version consistency**: Locked tool versions prevent unexpected changes
3. **Dependency isolation**: No conflicts with host system
4. **Automated backups**: Safe rollback on errors

> ⚠️ **Critical**: Never run build/update commands directly on host. Always use Docker containers.

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Python Packaging User Guide](https://packaging.python.org/en/latest/)
- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
