#!/bin/bash

# Quick fix script for config.js loading issues
# This replaces <script src="config.js"></script> with inline config

cd /home/user/webapp/public

# Define the inline config replacement
INLINE_CONFIG='<script>
        \/\/ Inline config to avoid file loading issues
        const SAFESTRIDE_CONFIG = {
            supabase: {
                url: '\''https:\/\/swzlxlfprtpxrttfscvf.supabase.co'\'',
                anonKey: '\''eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN3emx4bGZwcnRweHJ0dGZzY3ZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ2MTU4NjcsImV4cCI6MjA1MDE5MTg2N30.Gq6j8Qu5yiWgzpzwqKa3zg9wZAqmY_FZeOVsPtdI5cs'\''
            },
            strava: {
                clientId: '\''139446'\'',
                clientSecret: '\''b58cec58bcc28f5ce8b05f6ee69d98b1ec2f8c55'\'',
                redirectUri: window.location.origin + '\''\/public\/strava-callback.html'\'',
                scope: '\''read,activity:read_all,profile:read_all'\''
            },
            aisri: {
                weights: {
                    running: 0.40,
                    strength: 0.15,
                    rom: 0.12,
                    balance: 0.13,
                    alignment: 0.10,
                    mobility: 0.10
                }
            }
        };
    <\/script>'

# List of files to fix
FILES=(
    "strava-callback.html"
    "strava-dashboard.html"
    "training-plan-builder.html"
    "oauth-debugger.html"
    "test-autofill.html"
)

echo "🔧 Fixing config.js loading issues in HTML files..."
echo ""

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "📝 Fixing $file..."
        sed -i 's/<script src="config.js"><\/script>/'"$INLINE_CONFIG"'/g' "$file"
        echo "   ✅ Fixed!"
    else
        echo "   ⚠️  File not found: $file"
    fi
done

echo ""
echo "✅ All files fixed!"
echo ""
echo "Files updated:"
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    fi
done
