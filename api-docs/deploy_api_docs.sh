#!/usr/bin/env bash
# AKURA SafeStride - API Documentation Deployment Script (Bash)
# Target: docs.api.akura.in (recommended) or /docs under backend
# Version: 1.0
# Last Updated: 2026-01-27

set -euo pipefail

ENVIRONMENT="${1:-staging}"         # staging or production
SPEC_FILE="${2:-./AKURA_API_Spec.yaml}"
PORT="${3:-8081}"
DEPLOY_DIR="./api-docs-deploy"
SWAGGER_UI_VERSION="5.10.5"
SWAGGER_UI_URL="https://github.com/swagger-api/swagger-ui/archive/refs/tags/v${SWAGGER_UI_VERSION}.tar.gz"

echo "🚀 AKURA API Documentation Deployment"
echo "Environment: ${ENVIRONMENT}"
echo "Spec File: ${SPEC_FILE}"
echo ""

# Step 0: Prechecks
for cmd in node npx curl tar; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Missing dependency: $cmd"; exit 1
  fi
done

# Step 1: Verify OpenAPI spec exists
if [ ! -f "$SPEC_FILE" ]; then
  echo "❌ Error: OpenAPI spec not found at $SPEC_FILE"; exit 1
fi
echo "✅ OpenAPI spec found"

# Step 2: Validate OpenAPI spec
echo "🔍 Validating OpenAPI spec..."
npx @apidevtools/swagger-cli validate "$SPEC_FILE"
echo "✅ OpenAPI spec is valid"

# Step 3: Create deployment directory
rm -rf "$DEPLOY_DIR" && mkdir -p "$DEPLOY_DIR"
echo "✅ Created deployment directory: $DEPLOY_DIR"

# Step 4: Download Swagger UI dist
echo "📦 Downloading Swagger UI v${SWAGGER_UI_VERSION}..."
curl -fsSL "$SWAGGER_UI_URL" -o "$DEPLOY_DIR/swagger-ui.tar.gz"
tar -xzf "$DEPLOY_DIR/swagger-ui.tar.gz" -C "$DEPLOY_DIR"
cp -r "$DEPLOY_DIR/swagger-ui-${SWAGGER_UI_VERSION}/dist/"* "$DEPLOY_DIR/"
rm -rf "$DEPLOY_DIR/swagger-ui-${SWAGGER_UI_VERSION}" "$DEPLOY_DIR/swagger-ui.tar.gz"
echo "✅ Swagger UI files ready"

# Step 5: Copy OpenAPI spec
cp "$SPEC_FILE" "$DEPLOY_DIR/akura-api-spec.yaml"
echo "✅ OpenAPI spec copied"

# Step 6: Configure Swagger UI (override swagger-initializer.js)
cat > "$DEPLOY_DIR/swagger-initializer.js" <<'EOF'
window.ui = SwaggerUIBundle({
  url: './akura-api-spec.yaml',
  dom_id: '#swagger-ui',
  deepLinking: true,
  presets: [
    SwaggerUIBundle.presets.apis,
    SwaggerUIStandalonePreset
  ],
  layout: 'BaseLayout'
});
EOF

# Update index.html title and branding
INDEX_HTML="$DEPLOY_DIR/index.html"
if [ -f "$INDEX_HTML" ]; then
  sed -i.bak 's|<title>Swagger UI</title>|<title>AKURA SafeStride API</title>|g' "$INDEX_HTML"
  cat >> "$INDEX_HTML" <<'CSS'
<style>
  .topbar { background-color: #1e3a5f !important; }
  .topbar .link { color: #33BEF3 !important; }
  .swagger-ui .info .title { color: #1e3a5f; }
  .swagger-ui .scheme-container { background-color: #f5f9fc; }
</style>
CSS
  rm -f "$INDEX_HTML.bak"
fi

echo "✅ Swagger UI configured"

# Step 7: Test locally
echo ""
echo "🌐 Starting local server for testing..."
echo "URL: http://localhost:${PORT}"
echo "Press Ctrl+C to stop the server"
echo ""
(
  cd "$DEPLOY_DIR" && npx http-server -p "$PORT" -c-1
)

# Step 8: Deployment Options
cat <<'OUT'

✅ Local test complete!

📤 Deployment Options:

OPTION A: Render Static Site (recommended: docs.api.akura.in)
  1) Create Static Site on Render
  2) Publish Directory: api-docs-deploy
  3) Add custom domain: docs.api.akura.in (keep backend at api.akura.in)

OPTION B: Netlify
  npx netlify-cli deploy --dir=api-docs-deploy --prod
  Add custom domain: docs.api.akura.in

OPTION C: Azure Static Web Apps
  az staticwebapp create --name akura-api-docs --resource-group akura-rg --source api-docs-deploy --location eastus2

OPTION D: Self-Hosted (Nginx)
  sudo cp -r api-docs-deploy/* /var/www/api-docs
  Configure server to serve /docs
  Set up SSL with Let's Encrypt

DNS Notes:
  CNAME docs.api.akura.in -> your static host
  CNAME api.akura.in      -> backend host (Render) for API
OUT
