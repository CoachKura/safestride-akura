#!/bin/bash

# Akura SafeStride - Quick Start Script
# This script helps you get started with development

echo "🚀 Akura SafeStride - Quick Start"
echo "=================================="
echo ""

# Check if VS Code is installed
if ! command -v code &> /dev/null; then
    echo "❌ VS Code not found!"
    echo "📥 Install VS Code from: https://code.visualstudio.com/"
    exit 1
fi

echo "✅ VS Code found!"
echo ""

# Check if in correct directory
if [ ! -f "VS_CODE_WORKFLOW.md" ]; then
    echo "⚠️  Warning: Not in project root directory"
    echo "📁 Please run this script from: E:\Akura Safe Stride\safestride"
    echo ""
fi

# Menu
echo "What would you like to do?"
echo ""
echo "1) 🆕 First Time Setup (install extensions, configure git)"
echo "2) 💻 Open VS Code with workspace"
echo "3) 🚀 Start development server"
echo "4) 📚 Open workflow guide"
echo "5) 🔄 Quick commit and push"
echo "6) 🗄️  Open Supabase dashboard"
echo "7) 🌐 Open live site"
echo "8) ❌ Exit"
echo ""

read -p "Enter your choice (1-8): " choice

case $choice in
    1)
        echo ""
        echo "🔧 Setting up development environment..."
        echo ""
        
        # Install recommended extensions
        echo "📦 Installing recommended VS Code extensions..."
        code --install-extension ritwickdey.liveserver
        code --install-extension esbenp.prettier-vscode
        code --install-extension bradlc.vscode-tailwindcss
        code --install-extension formulahendry.auto-rename-tag
        code --install-extension formulahendry.auto-close-tag
        code --install-extension christian-kohler.path-intellisense
        code --install-extension eamodio.gitlens
        code --install-extension donjayamanne.githistory
        
        echo ""
        echo "🔐 Configuring Git..."
        git config --global credential.helper store
        git config --global core.autocrlf true
        
        echo ""
        echo "✅ Setup complete!"
        echo "📖 Opening workflow guide..."
        code VS_CODE_WORKFLOW.md
        ;;
        
    2)
        echo ""
        echo "💻 Opening VS Code..."
        code .
        ;;
        
    3)
        echo ""
        echo "🚀 Starting development server on port 3000..."
        echo "🌐 Access at: http://localhost:3000"
        echo ""
        echo "Press Ctrl+C to stop the server"
        cd frontend
        python3 -m http.server 3000
        ;;
        
    4)
        echo ""
        echo "📚 Opening workflow guide..."
        code VS_CODE_WORKFLOW.md
        ;;
        
    5)
        echo ""
        read -p "📝 Enter commit message: " commit_msg
        echo ""
        echo "🔄 Committing and pushing..."
        git add .
        git commit -m "$commit_msg"
        git push origin main
        echo ""
        echo "✅ Changes pushed to GitHub!"
        echo "⏳ Vercel will deploy in ~2 minutes"
        ;;
        
    6)
        echo ""
        echo "🗄️  Opening Supabase dashboard..."
        # For Windows
        start "https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro" 2>/dev/null || \
        # For macOS
        open "https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro" 2>/dev/null || \
        # For Linux
        xdg-open "https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro" 2>/dev/null
        ;;
        
    7)
        echo ""
        echo "🌐 Opening live site..."
        # For Windows
        start "https://www.akura.in" 2>/dev/null || \
        # For macOS
        open "https://www.akura.in" 2>/dev/null || \
        # For Linux
        xdg-open "https://www.akura.in" 2>/dev/null
        ;;
        
    8)
        echo ""
        echo "👋 Goodbye!"
        exit 0
        ;;
        
    *)
        echo ""
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac
