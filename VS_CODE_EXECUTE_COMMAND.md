# 🚀 VS Code Execute Command - SafeStride

## 📍 IMPORTANT: Project Location
**Always use this path**: `C:\safestride\webapp`

---

## ▶️ QUICK EXECUTE COMMAND (Copy-Paste)

### Method 1: Live Server (RECOMMENDED)
```
1. Open VS Code
2. File → Open Folder → C:\safestride\webapp
3. Click public/onboarding.html
4. Right-click → "Open with Live Server"
5. Browser opens automatically at http://127.0.0.1:5500/public/onboarding.html
```

### Method 2: Python Server (Terminal)
```powershell
# In VS Code Terminal (Ctrl+`)
cd C:\safestride\webapp\public
python -m http.server 8000

# Then open browser:
# http://localhost:8000/onboarding.html
```

### Method 3: Node.js Server (Terminal)
```powershell
# In VS Code Terminal (Ctrl+`)
cd C:\safestride\webapp\public
npx http-server -p 8000

# Then open browser:
# http://localhost:8000/onboarding.html
```

---

## 🎯 ONE-LINE COMMANDS FOR FUTURE USE

### Live Server Command
```
Open: C:\safestride\webapp → Right-click public/onboarding.html → Open with Live Server
```

### Python Command
```powershell
cd C:\safestride\webapp\public && python -m http.server 8000
```

### Node.js Command
```powershell
cd C:\safestride\webapp\public && npx http-server -p 8000
```

---

## 📋 STANDARD WORKFLOW (Memorize This)

### Every Time You Start:
1. **Open VS Code**
2. **Open Folder**: `C:\safestride\webapp`
3. **Open File**: `public/onboarding.html` (or any page you need)
4. **Execute**: Right-click → "Open with Live Server"
5. **Result**: Browser opens at `http://127.0.0.1:5500/public/[filename].html`

### Files You Can Execute:
- `public/onboarding.html` - Athlete onboarding
- `public/athlete-dashboard.html` - Dashboard
- `public/training-calendar.html` - Training calendar
- `public/athlete-evaluation.html` - Evaluation form
- `public/generate-training-plan-ui.html` - Data generator

---

## 🔧 VS Code Tasks (Optional - Advanced)

Create `.vscode/tasks.json` in `C:\safestride\webapp`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Start SafeStride",
      "type": "shell",
      "command": "cd public && python -m http.server 8000",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

Then run: `Ctrl+Shift+P` → "Tasks: Run Task" → "Start SafeStride"

---

## 🎛️ VS Code Launch Configuration (Optional)

Create `.vscode/launch.json` in `C:\safestride\webapp`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Open SafeStride",
      "type": "chrome",
      "request": "launch",
      "url": "http://127.0.0.1:5500/public/onboarding.html",
      "webRoot": "${workspaceFolder}/public"
    }
  ]
}
```

Then press `F5` to launch with debugging!

---

## 📌 MEMORIZE THESE KEY POINTS

### 1. Project Location
```
C:\safestride\webapp
```

### 2. Execute Command
```
Right-click HTML file → "Open with Live Server"
```

### 3. URL Pattern
```
http://127.0.0.1:5500/public/[filename].html
```

### 4. Terminal Command (Alternative)
```powershell
cd C:\safestride\webapp\public && python -m http.server 8000
```

---

## 🎯 QUICK REFERENCE CARD

| Action | Command |
|--------|---------|
| **Open Project** | VS Code → Open Folder → `C:\safestride\webapp` |
| **Run Page** | Right-click HTML → "Open with Live Server" |
| **Open Terminal** | Press `Ctrl+\`` (backtick) |
| **Python Server** | `cd C:\safestride\webapp\public && python -m http.server 8000` |
| **View in Browser** | `http://127.0.0.1:5500/public/[file].html` |
| **Stop Server** | Click "Port: 5500" in bottom-right → Stop |

---

## 🚀 FASTEST WORKFLOW (< 10 seconds)

```
1. Open VS Code
2. Recent → C:\safestride\webapp (if already opened before)
3. Click public/onboarding.html
4. Alt+L Alt+O (Live Server shortcut)
5. ✅ Running!
```

**Keyboard Shortcut**: `Alt+L Alt+O` opens Live Server immediately!

---

## 📱 FOR MOBILE TESTING

If you want to test on your phone:

1. Find your computer's IP:
```powershell
ipconfig
# Look for IPv4 Address (e.g., 192.168.1.100)
```

2. On your phone, open:
```
http://192.168.1.100:5500/public/onboarding.html
```

(Make sure phone and computer are on same WiFi)

---

## 🔄 RESTART WORKFLOW

If something breaks:

```
1. Close browser
2. VS Code bottom-right: Click "Port: 5500" → Stop
3. Wait 2 seconds
4. Right-click HTML file → "Open with Live Server"
5. ✅ Fresh start!
```

---

## 💾 SAVE THIS COMMAND PATTERN

**Template for Future Projects**:
```
Location: C:\[project-name]\webapp
Open: VS Code → Open Folder → Location
Execute: Right-click [file].html → "Open with Live Server"
URL: http://127.0.0.1:5500/public/[file].html
```

**For SafeStride**:
```
Location: C:\safestride\webapp
Open: VS Code → Open Folder → C:\safestride\webapp
Execute: Right-click public/onboarding.html → "Open with Live Server"
URL: http://127.0.0.1:5500/public/onboarding.html
```

---

## 🎓 MEMORIZATION CHECKLIST

- [ ] Project is at `C:\safestride\webapp`
- [ ] Main files are in `public/` folder
- [ ] Use "Open with Live Server" to run
- [ ] URL is `http://127.0.0.1:5500/public/[file].html`
- [ ] Alternative: `cd public && python -m http.server 8000`
- [ ] Shortcut: `Alt+L Alt+O` to launch Live Server

---

## 📞 FUTURE REFERENCE

Whenever you need to run SafeStride:

**Say**: "Run SafeStride in VS Code"

**I'll remember**:
- Location: `C:\safestride\webapp`
- Method: Live Server
- Files: `public/*.html`
- URL: `http://127.0.0.1:5500/public/`

---

## ✅ CONFIRMED SETTINGS

```
Project Path:     C:\safestride\webapp
Execute Method:   Live Server (preferred)
Port:            5500 (Live Server) or 8000 (Python)
Files Location:   public/
Primary File:     public/onboarding.html
```

**Status**: ✅ MEMORIZED FOR FUTURE USE

---

Created: March 4, 2026  
Project: SafeStride  
Location: C:\safestride\webapp  
Method: Live Server (VS Code Extension)  
Status: ✅ Ready to execute anytime
