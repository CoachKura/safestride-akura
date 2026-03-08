# 🚀 SafeStride Local Development - QUICK START

## ✅ SETUP COMPLETE!

Your VS Code is now configured for local SafeStride development.

---

## 🎯 METHOD 1: Live Server (FASTEST - RECOMMENDED)

### Install Extension (One-Time Setup):
1. Open VS Code
2. Press `Ctrl+Shift+X` (Extensions)
3. Search: **"Live Server"** by Ritwick Dey
4. Click **Install**

### Run SafeStride:
1. Open `C:\safestride\webapp` in VS Code
2. Open any HTML file (e.g., `public/onboarding.html`)
3. Right-click in editor → **"Open with Live Server"**
4. Browser opens automatically! 🎉

**Shortcut**: `Alt+L Alt+O`

### URLs:
- Onboarding: http://127.0.0.1:5500/public/onboarding.html
- Dashboard: http://127.0.0.1:5500/public/athlete-dashboard.html
- Calendar: http://127.0.0.1:5500/public/training-calendar.html

---

## 🎯 METHOD 2: VS Code Tasks (Alternative)

1. Press `Ctrl+Shift+P`
2. Type: "Tasks: Run Task"
3. Select: **"Start SafeStride Local"**
4. Open browser: http://localhost:8000/onboarding.html

---

## 🎯 METHOD 3: F5 Debug Launch (With Breakpoints!)

1. Open `public/onboarding.html`
2. Press `F5`
3. Select: **"Open SafeStride Onboarding"**
4. Chrome opens with DevTools attached!

**Debug Configurations Available**:
- Open SafeStride Onboarding
- Open SafeStride Dashboard
- Open Training Calendar

---

## 📁 Project Structure

```
C:\safestride\
├── web/              → Production (Deployed to Cloudflare)
└── webapp/
    └── public/       → Local Development (YOU'RE HERE)
        ├── onboarding.html
        ├── athlete-dashboard.html
        ├── training-calendar.html
        ├── athlete-evaluation.html
        └── generate-training-plan-ui.html
```

---

## 🌐 Deployment URLs

### Production (Live):
✅ https://safestride.pages.dev/
✅ https://f0bf8d6a.safestride.pages.dev/ (Latest deployment)

### Local Development:
🚀 http://127.0.0.1:5500/public/ (Live Server)
🚀 http://localhost:8000/ (Python Server)

---

## ⚡ QUICKEST WORKFLOW (< 5 seconds)

```
1. VS Code → Recent → webapp
2. Click public/onboarding.html
3. Alt+L Alt+O
4. ✅ Running!
```

---

## 🔄 Make Changes & See Live Updates

1. Edit any HTML/CSS/JS file
2. Save (`Ctrl+S`)
3. Browser auto-refreshes! ✨ (with Live Server)

---

## 🛠️ Troubleshooting

### "Live Server not found"
→ Install extension: `Ctrl+Shift+X` → Search "Live Server" → Install

### Port already in use
→ Bottom-right corner → Click "Port: 5500" → Stop → Try again

### Page not loading
→ Make sure you opened the **webapp** folder, not safestride root

---

## 📌 WHAT YOU HAVE NOW

✅ VS Code tasks configured (`.vscode/tasks.json`)
✅ Debug launch configs (`.vscode/launch.json`)
✅ Local development ready
✅ Production deployed to Cloudflare Pages

---

**Created**: March 4, 2026
**Last Updated**: Now
**Status**: ✅ READY TO CODE!

---

## 🎓 Remember This:

**For Local Testing**: `C:\safestride\webapp` + Live Server
**For Production**: Already deployed to `safestride.pages.dev`

**Next Step**: Copy the correct deployment URL to test online:
```
https://f0bf8d6a.safestride.pages.dev/onboarding
```
(NOT f0bl6d3a - that was the typo!)

