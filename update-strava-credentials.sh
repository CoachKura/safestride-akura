#!/bin/bash
# Strava Credentials Update Script
# This script updates Strava credentials across all files

echo "🔧 SafeStride - Strava Credentials Update Tool"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Current credentials (to be replaced)
OLD_CLIENT_ID="162971"
OLD_CLIENT_SECRET="6554eb9bb83f222a585e312c17420221313f85c1"

# Prompt for new credentials
echo "📝 Please enter your Strava app credentials:"
echo ""
read -p "New Client ID: " NEW_CLIENT_ID
read -p "New Client Secret: " NEW_CLIENT_SECRET

# Validate inputs
if [ -z "$NEW_CLIENT_ID" ] || [ -z "$NEW_CLIENT_SECRET" ]; then
    echo "${RED}❌ Error: Both Client ID and Client Secret are required${NC}"
    exit 1
fi

echo ""
echo "${YELLOW}⚠️  This will update credentials in the following files:${NC}"
echo "  1. supabase/functions/strava-oauth/index.ts"
echo "  2. supabase/functions/strava-sync-activities/index.ts"
echo "  3. public/config.js"
echo "  4. public/training-plan-builder.html"
echo "  5. public/device-aifri-connector.js"
echo "  6. js/device-aifri-connector.js (if exists)"
echo ""
read -p "Continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "${RED}❌ Cancelled${NC}"
    exit 0
fi

echo ""
echo "🔄 Updating credentials..."

# Function to update file
update_file() {
    local file=$1
    if [ -f "$file" ]; then
        # Create backup
        cp "$file" "${file}.backup"
        
        # Replace Client ID
        sed -i.tmp "s/${OLD_CLIENT_ID}/${NEW_CLIENT_ID}/g" "$file"
        
        # Replace Client Secret
        sed -i.tmp "s/${OLD_CLIENT_SECRET}/${NEW_CLIENT_SECRET}/g" "$file"
        
        # Remove temporary file
        rm -f "${file}.tmp"
        
        echo "${GREEN}✅ Updated: $file${NC}"
    else
        echo "${YELLOW}⚠️  Skipped (not found): $file${NC}"
    fi
}

# Update all files
update_file "supabase/functions/strava-oauth/index.ts"
update_file "supabase/functions/strava-sync-activities/index.ts"
update_file "public/config.js"
update_file "public/training-plan-builder.html"
update_file "public/device-aifri-connector.js"
update_file "js/device-aifri-connector.js"

echo ""
echo "${GREEN}✅ All files updated!${NC}"
echo ""
echo "📋 Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit changes: git add -A && git commit -m 'Update Strava credentials'"
echo "  3. Deploy Edge Functions:"
echo "     supabase functions deploy strava-oauth"
echo "     supabase functions deploy strava-sync-activities"
echo "  4. Test OAuth flow"
echo ""
echo "${YELLOW}⚠️  Backup files created with .backup extension${NC}"
echo ""
