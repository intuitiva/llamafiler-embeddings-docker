#!/bin/bash

# === CONFIG ===
SERVICE_NAME="llamafiler-embeddings"
REGION="us-east-1"
VERSION_TAG=$(date +%s) # Generate a unique tag based on the current timestamp

APP_IMAGE_NAME="llamafiler-embeddings"
NGINX_IMAGE_NAME="llamafiler-embeddings-nginx"

# Load environment variables from .env file
if [[ -f ".env" ]]; then
  echo "📋 Loading environment variables from .env file..."
  export $(grep -v '^#' .env | xargs)
else
  echo "⚠️  No .env file found, using default values"
fi

# === 1. Create Lightsail container service (if it doesn't exist) ===
echo "🏗 Checking if Lightsail container service exists..."
if ! aws lightsail get-container-services --service-name $SERVICE_NAME --region $REGION >/dev/null 2>&1; then
  echo "📦 Creating Lightsail container service: $SERVICE_NAME"
  aws lightsail create-container-service \
    --service-name $SERVICE_NAME \
    --power micro \
    --scale 1 \
    --region $REGION
  
  echo "⏳ Waiting for container service to be ready..."
  aws lightsail wait container-service-deployed --service-name $SERVICE_NAME --region $REGION
else
  echo "✅ Container service $SERVICE_NAME already exists"
fi

# === Get the registry URL ===
echo "🔍 Getting registry URL..."
# For Lightsail, we need to push to the service-specific registry
REGISTRY="$SERVICE_NAME" # This is just for reference, not used in image name
echo "📋 Registry reference: $REGISTRY"

# === 2. Build Docker images ===
echo "🔨 Building Docker images with tag '$VERSION_TAG' for AMD64 architecture..."
docker build --platform linux/amd64 -t "$APP_IMAGE_NAME:$VERSION_TAG" -f Dockerfile .
docker build --platform linux/amd64 -t "$NGINX_IMAGE_NAME:$VERSION_TAG" -f nginx.dockerfile .

# === 3. Push images directly to Lightsail ===
echo "🚀 Pushing images to Lightsail container service..."
aws lightsail push-container-image \
  --region $REGION \
  --service-name $SERVICE_NAME \
  --label $APP_IMAGE_NAME \
  --image "$APP_IMAGE_NAME:$VERSION_TAG"

aws lightsail push-container-image \
  --region $REGION \
  --service-name $SERVICE_NAME \
  --label $NGINX_IMAGE_NAME \
  --image "$NGINX_IMAGE_NAME:$VERSION_TAG"

# === 5. Create containers.json from template ===
echo "📝 Creating containers.json from template..."
if [[ ! -f "containers.template.json" ]]; then
  echo "❌ Error: containers.template.json not found!"
  exit 1
fi

# Set default values if not provided
AUTH_USERNAME="${AUTH_USERNAME:-admin}"
AUTH_PASSWORD="${AUTH_PASSWORD:-changeme}"

# Create containers.json by substituting variables in template
# For Lightsail, we reference images by their label:tag format (no registry prefix)
sed \
  -e "s|{{REGISTRY}}/||g" \
  -e "s|:latest|:$VERSION_TAG|g" \
  -e "s|{{APP_IMAGE_NAME}}|$APP_IMAGE_NAME|g" \
  -e "s|{{NGINX_IMAGE_NAME}}|$NGINX_IMAGE_NAME|g" \
  -e "s|{{AUTH_USERNAME}}|$AUTH_USERNAME|g" \
  -e "s|{{AUTH_PASSWORD}}|$AUTH_PASSWORD|g" \
  containers.template.json > containers.json

# === 6. Create or update Lightsail service deployment ===
echo "🚀 Deploying to Lightsail container service..."
aws lightsail create-container-service-deployment \
  --region $REGION \
  --service-name $SERVICE_NAME \
  --cli-input-json file://containers.json

echo "✅ Deployment complete!"