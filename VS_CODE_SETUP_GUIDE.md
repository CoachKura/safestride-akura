# 🚀 VS Code Setup Guide for SafeStride

## 📦 Step 1: Extract the Downloaded File

1. **Locate the downloaded file**: 
   - Look in your Downloads folder
   - File name: `safestride-config-fix-2026-03-04.tar.gz` (or similar)

2. **Extract the file**:
   - **Option A**: Use 7-Zip or WinRAR (Windows)
     - Right-click → Extract Here
     - May need to extract twice (tar.gz is double compressed)
   
   - **Option B**: Use Windows built-in extractor
     - Right-click → Extract All
   
   - **Option C**: Use PowerShell
     ```powershell
     # Navigate to Downloads folder
     cd C:\Users\YourUsername\Downloads
     
     # Extract (if you have tar)
     tar -xzf safestride-config-fix-2026-03-04.tar.gz
     ```

3. **Result**: You should have a folder structure like:
   ```
   webapp/
   ├── public/
   │   ├── onboarding.html
   │   ├── athlete-dashboard.html
   │   ├── training-calendar.html
   │   ├── athlete-evaluation.html
   │   └── ... (more files)
   ├── migrations/
   ├── README.md
   └── ... (other files)
   ```

---

## 📂 Step 2: Open Project in VS Code

### **Method 1: Drag & Drop**
1. Open VS Code
2. Drag the `webapp` folder into VS Code window
3. Done! ✅

### **Method 2: File Menu**
1. Open VS Code
2. Go to **File** → **Open Folder**
3. Navigate to the extracted `webapp` folder
4. Click **Select Folder**
5. Done! ✅

### **Method 3: Command Line**
```powershell
# Navigate to the webapp folder
cd C:\path\to\webapp

# Open in VS Code
code .
```

---

## 🔧 Step 3: Install Live Server Extension

This is the **EASIEST** way to run your project!

### **Install Live Server:**

1. In VS Code, click the **Extensions** icon (left sidebar)
   - Or press `Ctrl+Shift+X`

2. Search for: **"Live Server"**

3. Find the one by **Ritwick Dey** (5-star rated, millions of downloads)

4. Click **Install**

5. Wait a few seconds for installation

6. ✅ Done!

---

## 🚀 Step 4: Run SafeStride

### **Using Live Server (RECOMMENDED):**

1. **Open the file** you want to run:
   - Click `public/onboarding.html` in the file explorer

2. **Start Live Server** (choose one method):
   
   **Method A**: Right-click in the editor
   - Right-click anywhere in the HTML file
   - Select **"Open with Live Server"**
   
   **Method B**: Bottom bar button
   - Look at the bottom-right corner of VS Code
   - Click **"Go Live"** button
   
   **Method C**: Command Palette
   - Press `Ctrl+Shift+P`
   - Type "Live Server: Open"
   - Press Enter

3. **Result**: 
   - Browser opens automatically
   - URL: `http://127.0.0.1:5500/public/onboarding.html`
   - ✅ Your app is running!

---

## 🎯 Step 5: Test the Onboarding Flow

Now that it's running:

1. **Fill in the form**:
   - Full Name: Kura D Sathyamoorthy
   - Email: contact@akura.in
   - Age: 47
   - Gender: Male
   - Weight: 82 kg
   - Height: 170 cm
   - Resting HR: 58 bpm
   - Max HR: 174 bpm

2. **Click "Next"** → Should move to Step 2 ✅

3. **Check console** (press F12):
   - No red errors
   - All scripts loaded
   - ✅ Working perfectly!

---

## 📁 Step 6: Explore Other Pages

### **Main Pages to Test:**

Open these files with Live Server:

1. **Onboarding**:
   ```
   public/onboarding.html
   ```
   4-step signup wizard

2. **Athlete Dashboard**:
   ```
   public/athlete-dashboard.html
   ```
   View today's workout, AISRI score, progress

3. **Training Calendar**:
   ```
   public/training-calendar.html
   ```
   12-week training plan view

4. **Evaluation Form**:
   ```
   public/athlete-evaluation.html
   ```
   6-pillar assessment with image capture

5. **Sample Data Generator**:
   ```
   public/generate-training-plan-ui.html
   ```
   Create 84 workouts for testing

---

## 🔥 Alternative: Use Python Server

If you prefer Python over Live Server:

### **Option A: VS Code Terminal**

1. **Open Terminal** in VS Code:
   - Press `Ctrl+`` (backtick)
   - Or: Menu → Terminal → New Terminal

2. **Navigate to public folder**:
   ```powershell
   cd public
   ```

3. **Start Python server**:
   ```powershell
   python -m http.server 8000
   ```

4. **Open browser**:
   - Go to: `http://localhost:8000/onboarding.html`

### **Option B: PowerShell Outside VS Code**

1. Open PowerShell

2. Navigate to project:
   ```powershell
   cd C:\path\to\webapp\public
   ```

3. Start server:
   ```powershell
   python -m http.server 8000
   ```

4. Open browser: `http://localhost:8000/onboarding.html`

---

## 🛠️ Recommended VS Code Extensions

Install these for better development:

### **Essential:**
1. **Live Server** (Ritwick Dey) - Already installed ✅
2. **HTML CSS Support** (ecmel) - Autocomplete
3. **JavaScript (ES6) code snippets** (charalampos karypidis)

### **Nice to Have:**
4. **Prettier** - Code formatting
5. **Auto Rename Tag** (Jun Han) - Edit HTML tags easily
6. **Path Intellisense** (Christian Kohler) - File path autocomplete

### **To Install:**
1. Press `Ctrl+Shift+X`
2. Search for extension name
3. Click Install
4. Reload VS Code if prompted

---

## 📊 VS Code Workspace Setup

### **Create a workspace for SafeStride:**

1. **File** → **Save Workspace As...**
2. Name: `SafeStride.code-workspace`
3. Save in the `webapp` folder

This saves your settings and open files!

### **Recommended Settings:**

Create `.vscode/settings.json`:

```json
{
  "liveServer.settings.port": 5500,
  "liveServer.settings.root": "/public",
  "liveServer.settings.CustomBrowser": "chrome",
  "editor.formatOnSave": true,
  "editor.tabSize": 2,
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/node_modules": true
  }
}
```

---

## 🐛 Troubleshooting

### **Issue 1: Live Server not starting**
**Solution**:
- Close VS Code completely
- Reopen the folder
- Try again
- Or use Python server instead

### **Issue 2: Page shows 404**
**Solution**:
- Make sure you're in the `public` folder
- URL should be: `http://127.0.0.1:5500/public/onboarding.html`
- Not: `http://127.0.0.1:5500/onboarding.html`

### **Issue 3: JavaScript errors**
**Solution**:
- Press F12 → Console tab
- Check if all files loaded (Network tab)
- Make sure you're using Live Server (not file://)
- Clear browser cache (Ctrl+Shift+Delete)

### **Issue 4: Can't install Live Server**
**Solution**:
- Use Python server instead (see above)
- Or install Node.js and use `npx http-server`

---

## 🎨 VS Code Tips for SafeStride

### **Keyboard Shortcuts:**
- `Ctrl+B` - Toggle sidebar
- `Ctrl+`` - Toggle terminal
- `Ctrl+P` - Quick file open
- `Ctrl+Shift+F` - Search in all files
- `Alt+Click` - Multiple cursors
- `Ctrl+/` - Toggle comment

### **Useful Commands:**
- Press `Ctrl+Shift+P` → Type:
  - "Format Document" - Auto-format code
  - "Live Server: Open" - Start server
  - "Live Server: Stop" - Stop server
  - "Developer: Reload Window" - Reload VS Code

---

## 📝 Quick Start Checklist

- [ ] Downloaded backup file
- [ ] Extracted to a folder
- [ ] Opened folder in VS Code
- [ ] Installed Live Server extension
- [ ] Right-clicked `public/onboarding.html`
- [ ] Selected "Open with Live Server"
- [ ] Browser opened automatically
- [ ] Tested onboarding form
- [ ] "Next" button works!
- [ ] No console errors (F12)

---

## 🎉 You're All Set!

### **What You Can Do Now:**

1. ✅ **Run SafeStride locally** in VS Code
2. ✅ **Test all features** (dashboard, calendar, evaluation)
3. ✅ **Generate sample data** for testing
4. ✅ **Edit files** and see changes live
5. ✅ **Deploy to GitHub Pages** when ready

### **Next Steps:**

1. **Test the onboarding flow** (most important!)
2. **Generate sample data** using the generator page
3. **View athlete dashboard** to see workouts
4. **Check training calendar** for 12-week plan
5. **Try evaluation form** for AISRI scoring

---

## 🆘 Need Help?

### **Common Questions:**

**Q: Which file should I open first?**  
A: Start with `public/onboarding.html`

**Q: Do I need to install anything?**  
A: Just the Live Server extension in VS Code

**Q: What if I don't have Python?**  
A: Use Live Server instead (easier!)

**Q: Can I edit the files?**  
A: Yes! Live Server auto-reloads when you save

**Q: How do I stop the server?**  
A: Click "Port: 5500" in bottom-right → Stop

---

## 📞 Support

If you encounter any issues:

1. **Check the console** (F12) for errors
2. **Verify you're using Live Server** (not file://)
3. **Make sure all files extracted properly**
4. **Try restarting VS Code**
5. **Ask me for help!** I'm here! 💪

---

**Created**: March 4, 2026  
**For**: VS Code + SafeStride setup  
**Status**: ✅ READY TO USE  
**Estimated Time**: 5-10 minutes

Happy coding! 🚀
