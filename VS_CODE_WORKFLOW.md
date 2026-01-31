# 🚀 VS CODE COMPLETE WORKFLOW GUIDE
## Akura SafeStride Development

> **ONE-CLICK CONTROL** for Git, Deployment, Supabase, and Local Development

---

## 📋 QUICK START

### **Open Project in VS Code**
```bash
# On your Windows machine:
cd "E:\Akura Safe Stride\safestride"
code .
```

---

## 🎯 ONE-CLICK TASKS (Ctrl+Shift+P → "Tasks: Run Task")

### **Development Tasks**
- 🚀 **Start Development Server** - Launches local server on port 3000
- 🔧 **Open Local Preview** - Opens http://localhost:3000 in browser
- 🧹 **Clean Port 3000** - Kills any process on port 3000

### **Git Operations**
- 🔄 **Git: Quick Commit & Push** - Add all, commit with message, push to GitHub
- 📊 **Git: Status** - Check current git status
- 📝 **Git: View Recent Commits** - Show last 10 commits
- 🔙 **Git: Pull Latest** - Pull latest changes from GitHub

### **Deployment**
- 🌐 **Deploy to Vercel** - Commit, push, and trigger deployment
- 🌐 **Open Live Site** - Opens https://www.akura.in

### **Supabase**
- 🗄️ **Supabase: Open SQL Editor** - Opens Supabase SQL Editor
- 🗄️ **Supabase: Open Auth Users** - Opens Supabase Auth Dashboard

### **Utilities**
- 📦 **Backup Project** - Creates timestamped backup tar.gz

---

## ⚡ KEYBOARD SHORTCUTS

| Action | Shortcut | Description |
|--------|----------|-------------|
| Run Task | `Ctrl+Shift+P` → "Tasks" | Access all tasks |
| Quick Open | `Ctrl+P` | Jump to any file |
| Command Palette | `Ctrl+Shift+P` | All VS Code commands |
| Integrated Terminal | `Ctrl+\`` | Toggle terminal |
| Git: Commit | `Ctrl+Enter` | (In Source Control) |
| Save All | `Ctrl+K S` | Save all files |
| Format Document | `Shift+Alt+F` | Auto-format code |

---

## 📁 PROJECT STRUCTURE

```
safestride/
├── .vscode/              # VS Code configuration
│   ├── settings.json     # Editor settings
│   ├── tasks.json        # One-click tasks
│   ├── launch.json       # Debug configurations
│   └── supabase.code-snippets  # SQL snippets
├── frontend/             # All HTML/CSS/JS files
│   ├── athlete-dashboard-pro.html
│   ├── track-workout.html
│   ├── assessment-intake.html
│   └── ...
├── backend/              # Backend logic (if any)
├── database/             # SQL migrations
└── supabase/             # Supabase config
```

---

## 🗄️ SUPABASE SQL SNIPPETS

Type these prefixes in SQL files to get quick templates:

| Prefix | Description |
|--------|-------------|
| `sb-profile-create` | Create/update user profile |
| `sb-query-user` | Query complete user data |
| `sb-assessment-insert` | Insert new assessment |
| `sb-check-columns` | Check table columns |
| `sb-data-audit` | Quick data audit |
| `sb-test-data` | Create test data |

---

## 🔄 TYPICAL WORKFLOW

### **1️⃣ Making Changes**
```
1. Open VS Code
2. Ctrl+P → Type filename → Edit
3. Ctrl+S to save (auto-saves after 1 second)
4. Changes visible immediately in browser (if using Live Server)
```

### **2️⃣ Testing Locally**
```
1. Ctrl+Shift+P → "🚀 Start Development Server"
2. Ctrl+Shift+P → "🔧 Open Local Preview"
3. Test your changes at http://localhost:3000
```

### **3️⃣ Committing to GitHub**
```
1. Ctrl+Shift+P → "🔄 Git: Quick Commit & Push"
2. Enter commit message
3. Changes pushed to GitHub automatically
```

### **4️⃣ Deploying to Production**
```
1. Ctrl+Shift+P → "🌐 Deploy to Vercel"
2. Enter deployment message
3. Wait 2 minutes
4. Ctrl+Shift+P → "🌐 Open Live Site"
5. Test at https://www.akura.in
```

### **5️⃣ Working with Supabase**
```
1. Ctrl+Shift+P → "🗄️ Supabase: Open SQL Editor"
2. Type snippet prefix (e.g., sb-query-user)
3. Tab to fill in values
4. Run query
5. Check results
```

---

## 🎨 RECOMMENDED VS CODE EXTENSIONS

Install these for best experience:

```
1. Live Server (ritwickdey.liveserver)
   → Auto-refresh on file save

2. Prettier (esbenp.prettier-vscode)
   → Auto-format code

3. Tailwind CSS IntelliSense (bradlc.vscode-tailwindcss)
   → Tailwind autocomplete

4. GitLens (eamodio.gitlens)
   → Enhanced Git features

5. Auto Rename Tag (formulahendry.auto-rename-tag)
   → Rename HTML tags in pairs

6. Path Intellisense (christian-kohler.path-intellisense)
   → Auto-complete file paths
```

**Install all at once:**
```bash
Ctrl+Shift+P → "Extensions: Show Recommended Extensions"
→ Click "Install All"
```

---

## 🐛 DEBUGGING

### **Launch Dashboard in Debug Mode**
```
1. Press F5 or Ctrl+Shift+D
2. Select "🚀 Launch Dashboard"
3. Browser opens with DevTools attached
4. Set breakpoints in JS code
5. Step through code execution
```

### **Common Debug Configurations**
- 🚀 Launch Dashboard (athlete-dashboard-pro.html)
- 🏃 Launch Workout Tracker (track-workout.html)
- 📝 Launch Assessment (assessment-intake.html)

---

## 🔧 TROUBLESHOOTING

### **Port 3000 Already in Use**
```bash
Ctrl+Shift+P → "🧹 Clean Port 3000"
```

### **Changes Not Showing**
```bash
# Hard refresh browser
Ctrl+Shift+R (Windows/Linux)
Cmd+Shift+R (macOS)
```

### **Git Authentication Issues**
```bash
# In terminal (Ctrl+`)
git config --global credential.helper store
git push  # Will prompt for credentials once
```

### **Supabase Connection Issues**
```bash
# Check .env or config files for correct URLs
# Verify Supabase project is active
Ctrl+Shift+P → "🗄️ Supabase: Open Auth Users"
```

---

## 📝 USEFUL TERMINAL COMMANDS

```bash
# Check git status
git status

# View changes
git diff

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# View git log
git log --oneline -10

# Create new branch
git checkout -b feature/new-feature

# Switch branch
git checkout main

# Pull latest
git pull origin main

# Force push (use carefully!)
git push -f origin main
```

---

## 🎯 PRODUCTION CHECKLIST

Before deploying to production:

- [ ] Test all pages locally
- [ ] Check console for errors (F12)
- [ ] Verify Supabase connections
- [ ] Test all forms and buttons
- [ ] Check mobile responsiveness (F12 → Device toolbar)
- [ ] Run git status to see changes
- [ ] Commit with descriptive message
- [ ] Push to GitHub
- [ ] Wait 2 minutes for Vercel deployment
- [ ] Test live site thoroughly
- [ ] Check Vercel deployment logs if issues

---

## 🌐 IMPORTANT URLS

| Service | URL | Purpose |
|---------|-----|---------|
| Live Site | https://www.akura.in | Production website |
| Supabase Dashboard | https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro | Database management |
| Supabase SQL Editor | [Link](https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro/sql/new) | Run SQL queries |
| Supabase Auth | [Link](https://supabase.com/dashboard/project/yawxlwcniqfspcgefuro/auth/users) | Manage users |
| GitHub Repo | https://github.com/CoachKura/safestride-akura | Source code |
| Local Dev | http://localhost:3000 | Local testing |

---

## 💡 PRO TIPS

1. **Use Live Server Extension**: Auto-refreshes browser on file save
2. **Enable Auto Save**: Already configured (saves after 1 second)
3. **Use GitLens**: See who changed what and when
4. **Use Prettier**: Auto-formats code on save
5. **Use Emmet**: Fast HTML/CSS writing (e.g., `div.container>ul>li*3`)
6. **Multi-cursor**: Alt+Click to add cursors, Ctrl+D to select next occurrence
7. **Split Editor**: Ctrl+\ to split, Ctrl+1/2/3 to focus
8. **Integrated Terminal**: Ctrl+` for quick terminal access
9. **Command Palette**: Ctrl+Shift+P for everything
10. **Quick Open**: Ctrl+P for instant file navigation

---

## 🚀 NEXT STEPS

1. **Open VS Code**: `code "E:\Akura Safe Stride\safestride"`
2. **Install Extensions**: Ctrl+Shift+P → "Show Recommended Extensions"
3. **Start Dev Server**: Ctrl+Shift+P → "🚀 Start Development Server"
4. **Make a test change**: Edit any HTML file
5. **Deploy**: Ctrl+Shift+P → "🌐 Deploy to Vercel"

---

## 📞 NEED HELP?

If you encounter issues:
1. Check this guide first
2. Check VS Code Output panel (View → Output)
3. Check browser console (F12)
4. Check Vercel deployment logs
5. Ask me for help!

---

**Last Updated**: January 2026
**Version**: 1.0.0
**Author**: AI Development Assistant
