# Docker Build Instructions

> ⚠️ **IMPORTANT**: All development and build operations for this project MUST be performed inside Docker containers. Do not run Python, pip, or build commands directly on the host machine.

## Quick Start with Docker Compose

### Build the package
```bash
docker-compose run --rm builder
```

Built artifacts (wheel and source distribution) will appear in `./dist/` directory.

### Interactive development shell
```bash
docker-compose run --rm dev
```

## Advantages of This Setup

- **No rebuilding**: Source files are mounted as volumes, changes are reflected immediately
- **Clean context**: Docker context is in `./docker/` directory, no need for `.dockerignore`
- **Automatic output**: Built packages appear directly in `./dist/` on your host machine

## Available Services

### `builder`
Builds the package and outputs to `./dist/`
```bash
docker-compose run --rm builder
```

### `dev`
Interactive bash shell for development and testing
```bash
docker-compose run --rm dev

# Inside the container you can:
python -m build --wheel --sdist
pip install -e .
python -c "import orbuculum_client; print(orbuculum_client.__version__)"
pytest  # Run tests
```

### `updater`
Updates the API client from the latest OpenAPI specification
```bash
docker-compose run --rm updater
```

This service automatically:
- Downloads the latest OpenAPI spec from https://s1.orbuculum.app/swagger/json
- Creates a backup of existing code
- Regenerates the client using OpenAPI Generator 7.15.0
- Verifies the generated code
- Provides next steps for testing and committing

**Note**: Files listed in `.openapi-generator-ignore` (like `pyproject.toml`) will NOT be overwritten.

See [API_UPDATES.md](API_UPDATES.md) for detailed information on the update process.

### `publisher`
Publishes the package to PyPI/TestPyPI
```bash
docker-compose run --rm publisher testpypi  # Test publishing (no git tags)
docker-compose run --rm publisher pypi      # Production publishing (creates git tag)
```

**Note:** Git operations (tagging) are automatically disabled for TestPyPI since it's a testing environment.

See [PUBLISHING.md](PUBLISHING.md) for detailed publishing instructions.

## Build Information

### Core Environment
- **Python version**: 3.13-slim (latest stable)
- **Build tools**: Latest stable versions of pip, setuptools, wheel, build, twine
- **Build backend**: setuptools (as defined in pyproject.toml)
- **Output**: Wheel (.whl) and source distribution (.tar.gz) in `./dist/`

### Code Generation Tools
- **OpenAPI Generator**: 7.15.0 (installed in container)
- **Generator library**: urllib3
- **Java Runtime**: OpenJDK headless (required for OpenAPI Generator)

### Important Dependencies
- **lazy-imports**: >=1,<2 (required for module loading)
- **pydantic**: >=2 (required for data validation)
- **typing-extensions**: >=4.7.1 (required for type hints)
- **urllib3**: >=2.1.0,<3.0.0 (HTTP client library)

> **Note**: All dependencies are pre-installed in the Docker image. If you encounter import errors, ensure you're using the Docker containers, not running commands directly on the host.

## Manual Docker Commands (without docker-compose)

### Build the image
```bash
docker build -t orbuculum-builder ./docker
```

### Build the package manually
```bash
docker run --rm \
  -v $(pwd)/pyproject.toml:/workspace/pyproject.toml:ro \
  -v $(pwd)/setup.cfg:/workspace/setup.cfg:ro \
  -v $(pwd)/requirements.txt:/workspace/requirements.txt:ro \
  -v $(pwd)/README.md:/workspace/README.md:ro \
  -v $(pwd)/LICENSE:/workspace/LICENSE:ro \
  -v $(pwd)/orbuculum:/workspace/orbuculum:ro \
  -v $(pwd)/dist:/workspace/dist \
  orbuculum-builder \
  python -m build --wheel --sdist --outdir /workspace/dist
```
