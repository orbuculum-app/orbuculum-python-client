# Custom Tests

This directory contains **custom tests** that you write manually. These tests are **never overwritten** by the API update process.

## Directory Structure

```
test/
├── generated/          # Auto-generated tests (regenerated on each API update)
│   ├── test_account.py
│   ├── test_account_api.py
│   └── ...
├── custom/            # Your custom tests (never overwritten)
│   ├── README.md (this file)
│   └── (your test files here)
└── __init__.py
```

## How It Works

### Generated Tests (`test/generated/`)
- **Automatically created** by OpenAPI Generator
- **Deleted and regenerated** on every API update (`docker-compose run --rm updater`)
- Provide basic smoke tests for models and API endpoints
- Good for verifying that API structure is correct

### Custom Tests (`test/custom/`)
- **Written by you** for specific business logic, edge cases, integration tests
- **Protected from deletion** - never touched by the update script
- Should test real-world scenarios, validation, error handling, etc.

## Usage Examples

### Running All Tests
```bash
# Run both generated and custom tests
docker-compose run --rm dev pytest test/

# Or outside Docker
pytest test/
```

### Running Only Custom Tests
```bash
# Run only your custom tests
docker-compose run --rm dev pytest test/custom/

# Or outside Docker
pytest test/custom/
```

### Running Only Generated Tests
```bash
# Run only auto-generated tests
docker-compose run --rm dev pytest test/generated/

# Or outside Docker
pytest test/generated/
```

## Best Practices

1. **Don't edit files in `test/generated/`** - they will be deleted on next update
2. **Write custom tests for**:
   - Complex business logic
   - Edge cases and error scenarios
   - Integration tests with real API
   - Custom validation logic
3. **Name your test files clearly**:
   - `test_account_custom.py` - custom tests for Account
   - `test_integration_auth.py` - integration tests for authentication
   - `test_edge_cases.py` - edge case tests

## Example Custom Test

```python
# test/custom/test_account_custom.py
import pytest
from orbuculum import AccountApi, ApiClient, Configuration

def test_account_creation_with_special_characters():
    """Test that account handles special characters in name"""
    # Your custom test logic here
    pass

def test_account_balance_edge_cases():
    """Test account balance with edge case values"""
    # Your custom test logic here
    pass
```

## What Happens During API Update

When you run `docker-compose run --rm updater`:

1. ✅ `test/custom/` - **Preserved** (your tests are safe)
2. ❌ `test/generated/` - **Deleted** and recreated with fresh tests
3. ✅ New API endpoints/models get new tests in `generated/`
4. ✅ Your custom tests continue to work

## Questions?

See the main project documentation or check `scripts/update_api.sh` for implementation details.
