# AKURA SafeStride - API Documentation Deployment Script
# Target: https://api.akura.in/docs (recommended to use docs.api.akura.in while DNS is pending)
# Version: 1.0
# Last Updated: 2026-01-27

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = "staging",  # Options: staging, production
    [Parameter(Mandatory=$false)]
    [string]$SpecFile = "./AKURA_API_Spec.yaml",
    [Parameter(Mandatory=$false)]
    [int]$Port = 8081
)

Write-Host "🚀 AKURA API Documentation Deployment" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host "Spec File: $SpecFile" -ForegroundColor Yellow
Write-Host "" 

# Step 0: Prechecks for Node and npx
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Node.js is required. Please install Node.js." -ForegroundColor Red
    exit 1
}
if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
    Write-Host "❌ npx is required. Please ensure Node.js >= 8 is installed." -ForegroundColor Red
    exit 1
}

# Step 1: Verify OpenAPI spec exists
if (-not (Test-Path $SpecFile)) {
    Write-Host "❌ Error: OpenAPI spec not found at $SpecFile" -ForegroundColor Red
    exit 1
}
Write-Host "✅ OpenAPI spec found" -ForegroundColor Green

# Step 2: Validate OpenAPI spec
Write-Host "🔍 Validating OpenAPI spec..." -ForegroundColor Yellow
npx @apidevtools/swagger-cli validate $SpecFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ OpenAPI spec validation failed" -ForegroundColor Red
    exit 1
}
Write-Host "✅ OpenAPI spec is valid" -ForegroundColor Green

# Step 3: Create deployment directory
$DeployDir = "./api-docs-deploy"
if (Test-Path $DeployDir) { Remove-Item -Recurse -Force $DeployDir }
New-Item -ItemType Directory -Path $DeployDir | Out-Null
Write-Host "✅ Created deployment directory: $DeployDir" -ForegroundColor Green

# Step 4: Download Swagger UI dist
Write-Host "📦 Downloading Swagger UI..." -ForegroundColor Yellow
$SwaggerUIVersion = "5.10.5"
$SwaggerUIUrl = "https://github.com/swagger-api/swagger-ui/archive/refs/tags/v$SwaggerUIVersion.zip"
$SwaggerUIZip = "$DeployDir/swagger-ui.zip"

Invoke-WebRequest -Uri $SwaggerUIUrl -OutFile $SwaggerUIZip
Expand-Archive -Path $SwaggerUIZip -DestinationPath $DeployDir -Force
Remove-Item $SwaggerUIZip

# Copy only dist folder
$SwaggerUIDistPath = "$DeployDir/swagger-ui-$SwaggerUIVersion/dist"
Copy-Item -Path "$SwaggerUIDistPath/*" -Destination $DeployDir -Recurse -Force
Remove-Item -Path "$DeployDir/swagger-ui-$SwaggerUIVersion" -Recurse -Force
Write-Host "✅ Swagger UI files ready" -ForegroundColor Green

# Step 5: Copy OpenAPI spec
Copy-Item -Path $SpecFile -Destination "$DeployDir/akura-api-spec.yaml"
Write-Host "✅ OpenAPI spec copied" -ForegroundColor Green

# Step 6: Configure Swagger UI via swagger-initializer.js
$Initializer = "$DeployDir/swagger-initializer.js"
$InitializerContent = @"
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
"@
Set-Content -Path $Initializer -Value $InitializerContent

# Update title and add branding in index.html
$IndexHtml = "$DeployDir/index.html"
$IndexContent = Get-Content $IndexHtml -Raw
$IndexContent = $IndexContent -replace '<title>Swagger UI</title>', '<title>AKURA SafeStride API</title>'
$CustomCSS = @"
<style>
  .topbar { background-color: #1e3a5f !important; }
  .topbar .link { color: #33BEF3 !important; }
  .swagger-ui .info .title { color: #1e3a5f; }
  .swagger-ui .scheme-container { background-color: #f5f9fc; }
</style>
"@
$IndexContent = $IndexContent -replace '</head>', "$CustomCSS`n</head>"
Set-Content -Path $IndexHtml -Value $IndexContent
Write-Host "✅ Swagger UI configured" -ForegroundColor Green

# Step 7: Test locally
Write-Host "" 
Write-Host "🌐 Starting local server for testing..." -ForegroundColor Cyan
Write-Host "URL: http://localhost:$Port" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
Write-Host "" 

Push-Location $DeployDir
Start-Process "http://localhost:$Port"
npx http-server -p $Port -c-1
Pop-Location

# Step 8: Deployment options and notes
Write-Host "" 
Write-Host "✅ Local test complete!" -ForegroundColor Green
Write-Host "" 
Write-Host "📤 Deployment Options:" -ForegroundColor Cyan
Write-Host "" 
Write-Host "OPTION A: Render Static Site (recommended subdomain: docs.api.akura.in)" -ForegroundColor Yellow
Write-Host "  1) Create Static Site on Render" -ForegroundColor Gray
Write-Host "  2) Publish Directory: api-docs-deploy" -ForegroundColor Gray
Write-Host "  3) Add custom domain: docs.api.akura.in (avoid conflict with backend at api.akura.in)" -ForegroundColor Gray
Write-Host "" 
Write-Host "OPTION B: Netlify" -ForegroundColor Yellow
Write-Host "  npx netlify-cli deploy --dir=$DeployDir --prod" -ForegroundColor Gray
Write-Host "  Add custom domain: docs.api.akura.in" -ForegroundColor Gray
Write-Host "" 
Write-Host "OPTION C: Azure Static Web Apps" -ForegroundColor Yellow
Write-Host "  az staticwebapp create --name akura-api-docs --resource-group akura-rg --source $DeployDir --location eastus2" -ForegroundColor Gray
Write-Host "" 
Write-Host "OPTION D: Self-Hosted (Nginx)" -ForegroundColor Yellow
Write-Host "  Copy $DeployDir to /var/www/api-docs and configure /docs path" -ForegroundColor Gray
Write-Host "  Ensure backend proxies /docs or host on docs.api.akura.in" -ForegroundColor Gray
