# Llamafiler Embeddings Docker Container

A secure Docker container setup for running [llamafiler](https://github.com/Mozilla-Ocho/llamafile) with the Qwen3 embedding model to provide local text embedding services with authentication.

## Overview

This secure setup includes:
- **llamafiler 0.9.3** - High-performance embedding server
- **Qwen3-Embedding-0.6B-Q8_0** - Multilingual embedding model
- **nginx reverse proxy** - With basic authentication and security features
- **APE loader** - For running Actually Portable Executables
- **Environment-based configuration** - For automated deployments

## Prerequisites

- Docker and Docker Compose installed on your system
- `curl` for downloading required files
- About 1GB of free disk space for the model and binary

## Setup

### 1. Clone or Download Project Files

```bash
git clone https://github.com/intuitiva/llamafiler-embeddings-docker
cd llamafiler-embeddings-docker
```

### 2. Download Required Files

Before building the Docker image, you need to download two large files locally:

```bash
# Download llamafiler binary (25MB)
curl -L -o llamafiler-0.9.3 https://github.com/Mozilla-Ocho/llamafile/releases/download/0.9.3/llamafiler-0.9.3

# Download Qwen3 embedding model (~700MB)
curl -L -o Qwen3-Embedding-0.6B-Q8_0.gguf https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF/resolve/main/Qwen3-Embedding-0.6B-Q8_0.gguf
```

### 3. Verify Your Files

Your directory should look like this:
```
├── dockerfile
├── nginx.dockerfile
├── nginx.conf
├── nginx-entrypoint.sh
├── docker-compose.yml
├── env.example
├── llamafiler-0.9.3
├── Qwen3-Embedding-0.6B-Q8_0.gguf
├── .gitignore
└── README.md
```

### 4. Configure Authentication (Required)

You **must** configure authentication before starting the containers. Choose one option:

**Option A: Using environment variables (recommended for automation)**
```bash
export AUTH_USERNAME=myuser
export AUTH_PASSWORD=mysecurepassword
```

**Option B: Using .env file (recommended for development)**
```bash
cp env.example .env
# Edit .env file and change AUTH_PASSWORD to a secure value
```

⚠️ **Important**: If you don't set authentication credentials, the nginx container will fail to start with permission errors.

## Running the Secure Server

### Quick Start

```bash
# With environment variables
AUTH_USERNAME=myuser AUTH_PASSWORD=mypassword docker-compose up -d

# Or with .env file
docker-compose up -d
```

### View Logs

```bash
docker-compose logs -f
```

### Stop the Server

```bash
docker-compose down
```

## Using the Secure Embedding Service

Once the server is running, you can access the embedding service at `http://localhost:8080`.

### Health Check (No Authentication Required)

```bash
curl http://localhost:8080/health
```

### Get Embeddings via API (Authentication Required)

```bash
curl -u myuser:mypassword -X POST http://localhost:8080/embedding \
  -H "Content-Type: application/json" \
  -d '{"content": "Hello world, this is a test sentence."}'
```

### Python Example

```python
import requests
from requests.auth import HTTPBasicAuth

response = requests.post(
    'http://localhost:8080/embedding', 
    json={'content': 'Your text here'},
    auth=HTTPBasicAuth('myuser', 'mypassword')
)
embeddings = response.json()
print(embeddings)
```

### Using with OpenAI-compatible API

```python
from openai import OpenAI
import base64

# Encode credentials for basic auth
credentials = base64.b64encode(b'myuser:mypassword').decode('utf-8')

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="no-key-required",
    default_headers={"Authorization": f"Basic {credentials}"}
)

response = client.embeddings.create(
    model="text-embedding",
    input="Your text to embed here"
)
print(response.data[0].embedding)
```

## Features

- **🔐 Secure by default** - Basic authentication with configurable credentials
- **🚀 Automated deployment** - Environment variable configuration
- **⚡ High performance** - Optimized for fast embedding generation
- **🌍 Multilingual support** - Qwen3 supports 119 languages
- **🔒 Local processing** - No data leaves your machine
- **🔄 OpenAI-compatible API** - Easy integration with existing tools
- **🛡️ Security features** - Rate limiting, request size limits, security headers
- **📦 Cross-platform compatibility** - Runs on x86_64 and ARM64

## Troubleshooting

### Authentication not working

Make sure your credentials are properly set:

```bash
# Check environment variables
echo $AUTH_USERNAME
echo $AUTH_PASSWORD

# Or check .env file
cat .env
```

### nginx error: "Permission denied" accessing .htpasswd

If you see an error like `open() "/etc/nginx/.htpasswd" failed (13: Permission denied)`, this means the authentication file wasn't created properly. 

**Solution:**
1. Make sure you have a `.env` file with authentication credentials:
   ```bash
   cp env.example .env
   # Edit .env and set AUTH_PASSWORD to a secure value
   ```

2. Rebuild the nginx container:
   ```bash
   docker-compose down
   docker-compose build --no-cache nginx
   docker-compose up -d
   ```

### Container fails to start with "exec format error"

This usually means the APE loader isn't properly configured. Try rebuilding:

```bash
docker-compose build --no-cache
```

### Model file not found

Make sure you downloaded the model file before building:

```bash
ls -la Qwen3-Embedding-0.6B-Q8_0.gguf
```

### Port already in use

Change the host port in docker-compose.yml:

```yaml
nginx:
  ports:
    - "8081:80"  # Change 8080 to 8081
```

### Slow embedding generation

The model runs on CPU by default. For better performance:
- Use a machine with more CPU cores
- Consider using a smaller model for faster inference
- Ensure adequate RAM (at least 4GB recommended)

## Development

### Development and Production Deployment

**Development with logs:**
```bash
docker-compose up  # Without -d to see logs
```

**Production deployment:**
```bash
# Using environment variables (CI/CD friendly)
export AUTH_USERNAME="production-user"
export AUTH_PASSWORD="$(openssl rand -base64 32)"
docker-compose up -d

# Or with secrets management
AUTH_USERNAME="$VAULT_USERNAME" AUTH_PASSWORD="$VAULT_PASSWORD" docker-compose up -d
```

**Building for Different Architectures:**
```bash
# Build for multiple architectures
docker-compose build --platform linux/amd64,linux/arm64
```

## Technical Details

- **Base Images**: Debian Stable (llamafiler) + nginx:alpine (proxy)
- **Port**: 8080 (HTTP with authentication)
- **Model Size**: ~700MB
- **Memory Usage**: ~2-4GB RAM
- **CPU**: Optimized for modern x86_64 and ARM64 processors
- **Security**: Basic HTTP authentication, rate limiting (60 req/min), request size limits (10MB)
- **Configuration**: Environment variables for automated deployment

## License

This project uses:
- llamafiler: Apache 2.0 License
- Qwen3 model: Check [Hugging Face model page](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF) for license details

## Contributing

1. Fork the repository
2. Make your changes
3. Test with `docker build -t llamafiler-embeddings .`
4. Submit a pull request

## Support

- [llamafile GitHub Issues](https://github.com/Mozilla-Ocho/llamafile/issues)
- [Qwen Model Documentation](https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF)

---

**Note**: The binary files (`llamafiler-0.9.3` and `Qwen3-Embedding-0.6B-Q8_0.gguf`) are not included in the git repository due to their size. You must download them locally before building the Docker image. 