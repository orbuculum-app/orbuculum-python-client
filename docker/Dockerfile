# Build Python package inside Docker container
# Uses latest stable Python and build tools

FROM python:3.13-slim

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    unzip \
    curl \
    git \
    default-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip, setuptools, wheel to latest stable versions
RUN pip install --no-cache-dir --upgrade pip setuptools wheel build twine

# Install test dependencies directly
RUN pip install --no-cache-dir \
    pytest>=7.2.1 \
    pytest-cov>=2.8.1 \
    tox>=3.9.0 \
    flake8>=4.0.0 \
    types-python-dateutil>=2.8.19.14 \
    mypy>=1.5 \
    python-dateutil>=2.8.2 \
    urllib3>=1.26.0 \
    'lazy-imports>=1,<2' \
    'pydantic>=2' \
    'typing-extensions>=4.7.1'

# Install OpenAPI Generator CLI
RUN curl -L https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/7.15.0/openapi-generator-cli-7.15.0.jar \
    -o /usr/local/bin/openapi-generator-cli.jar \
    && echo '#!/bin/bash\njava -jar /usr/local/bin/openapi-generator-cli.jar "$@"' > /usr/local/bin/openapi-generator-cli \
    && chmod +x /usr/local/bin/openapi-generator-cli

# Default command - build the package
CMD ["python", "-m", "build", "--wheel", "--sdist", "--outdir", "/workspace/dist"]
