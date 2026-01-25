#!/bin/bash

# SafeStride by AKURA - Quick Setup Script
# This script helps you set up the development environment

echo "🏃 SafeStride by AKURA - Setup Script"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check Node.js version
echo "📦 Checking Node.js version..."
NODE_VERSION=$(node -v 2>/dev/null)
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Node.js is not installed${NC}"
    echo "Please install Node.js 18+ from https://nodejs.org/"
    exit 1
fi

echo -e "${GREEN}✅ Node.js version: $NODE_VERSION${NC}"
echo ""

# Backend setup
echo "🔧 Setting up Backend..."
cd backend

if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Backend package.json not found${NC}"
    exit 1
fi

# Install backend dependencies
echo "Installing backend dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install backend dependencies${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend dependencies installed${NC}"

# Check for .env file
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found${NC}"
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo -e "${YELLOW}⚠️  Please edit backend/.env with your credentials${NC}"
    echo ""
fi

cd ..

# Frontend setup
echo "🎨 Setting up Frontend..."
cd frontend

if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ Frontend package.json not found${NC}"
    exit 1
fi

# Install frontend dependencies
echo "Installing frontend dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to install frontend dependencies${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Frontend dependencies installed${NC}"

# Check for .env.local file
if [ ! -f ".env.local" ]; then
    echo -e "${YELLOW}⚠️  .env.local file not found${NC}"
    echo "Creating .env.local from .env.example..."
    cp .env.example .env.local
    echo -e "${YELLOW}⚠️  Please edit frontend/.env.local with your backend URL${NC}"
    echo ""
fi

cd ..

# Summary
echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Configure Environment Variables:"
echo "   - Edit backend/.env with Supabase and Strava credentials"
echo "   - Edit frontend/.env.local with backend URL"
echo ""
echo "2. Set up Database:"
echo "   - Go to https://supabase.com/dashboard"
echo "   - Create a new project"
echo "   - Run database/schema.sql in SQL Editor"
echo ""
echo "3. Start Development Servers:"
echo "   Terminal 1 (Backend):"
echo "   $ cd backend && npm run dev"
echo ""
echo "   Terminal 2 (Frontend):"
echo "   $ cd frontend && npm run dev"
echo ""
echo "4. Open in Browser:"
echo "   http://localhost:5173"
echo ""
echo "📚 Documentation:"
echo "   - Quick Start: README.md"
echo "   - Deployment: DEPLOYMENT_GUIDE.md"
echo "   - Full Index: INDEX.md"
echo ""
echo "🎯 Current Status:"
echo "   Backend: 100% Complete ✅"
echo "   Frontend: 60% Complete ⚠️"
echo "   Deploy Ready: Backend ✅ | Frontend needs 8 pages"
echo ""
echo "Happy coding! 🚀"
