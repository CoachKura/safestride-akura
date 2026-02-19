@echo off
echo ==========================================
echo  AKURA SafeStride - GitHub Pages Deploy
echo ==========================================
echo.

REM Navigate to project directory
cd /d "C:\safestride-web"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not find C:\safestride-web
    echo Please update the path in this script.
    pause
    exit /b 1
)

echo Step 1: Fetching latest changes...
git fetch origin production
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git fetch failed
    pause
    exit /b 1
)

echo.
echo Step 2: Checking out production branch...
git checkout production
git pull origin production

echo.
echo Step 3: Creating gh-pages branch...
git checkout -b gh-pages 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Created new gh-pages branch
) else (
    echo gh-pages branch already exists, switching to it
    git checkout gh-pages
)

echo.
echo Step 4: Pushing to GitHub...
git push -u origin gh-pages
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Git push failed
    echo Please check your GitHub authentication
    pause
    exit /b 1
)

echo.
echo ==========================================
echo  SUCCESS! Branch pushed to GitHub
echo ==========================================
echo.
echo NEXT STEP (Do this manually):
echo 1. Go to: https://github.com/CoachKura/safestride-akura/settings/pages
echo 2. Under "Source": Select "gh-pages" branch
echo 3. Click "Save"
echo 4. Wait 2 minutes
echo.
echo Your site will be live at:
echo https://coachkura.github.io/safestride-akura/training-plan-builder.html
echo.
pause
