# FastAPI Server Startup Guide

## 🚀 Command Explanation

```bash
uvicorn main:app --host 0.0.0.0 --port $PORT
```

### What Each Part Does:

- **`uvicorn`** - ASGI server that runs FastAPI applications
- **`main:app`** - Tells uvicorn to import `app` from `main.py`
- **`--host 0.0.0.0`** - Binds to ALL network interfaces (allows external access)
- **`--port $PORT`** - Uses the PORT environment variable (defaults to 8001)

## 🔧 Startup Options

### Option 1: Direct Command (PowerShell)

```powershell
cd C:\safestride\ai_agents
$env:PORT = "8001"
uvicorn main:app --host 0.0.0.0 --port $env:PORT
```

### Option 2: Python Script

```bash
python start_server.py
```

### Option 3: PowerShell Script

```powershell
.\start_server.ps1
```

### Option 4: Batch File (Double-click)

```
start_server.bat
```

### Option 5: Original Method

```bash
python main.py
```

## 🌐 Host Binding Explained

| Host        | Description    | Access                   |
| ----------- | -------------- | ------------------------ |
| `127.0.0.1` | Localhost only | Only from same machine   |
| `0.0.0.0`   | All interfaces | From anywhere on network |

**Using `0.0.0.0` allows:**

- ✅ Access from your local network (other devices)
- ✅ Access from Flutter app on physical phone
- ✅ Access from Docker containers
- ⚠️ **Security Note:** Only use on trusted networks

## 🔒 Production vs Development

### Development (Current Setup)

```bash
uvicorn main:app --host 0.0.0.0 --port 8001
```

### Production (With Auto-Reload)

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

### Production (With Workers)

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --workers 4
```

### Production (Behind Proxy)

```bash
uvicorn main:app --host 127.0.0.1 --port 8001 --proxy-headers
```

## 📡 Accessing the Server

Once running, access from:

**Same Machine:**

- http://localhost:8001
- http://127.0.0.1:8001

**Other Devices on Network:**

- http://YOUR_IP:8001
  (Find your IP: `ipconfig` on Windows)

**API Documentation:**

- http://localhost:8001/docs (Swagger UI)
- http://localhost:8001/redoc (ReDoc)

## 🔌 Port Configuration

### Set Custom Port

**PowerShell:**

```powershell
$env:PORT = "8080"
uvicorn main:app --host 0.0.0.0 --port $env:PORT
```

**Bash/Linux:**

```bash
export PORT=8080
uvicorn main:app --host 0.0.0.0 --port $PORT
```

**Hardcoded:**

```bash
uvicorn main:app --host 0.0.0.0 --port 8080
```

## 🐛 Troubleshooting

### Port Already in Use

```powershell
# Find what's using port 8001
netstat -ano | findstr ":8001"

# Kill the process
Stop-Process -Id <PID> -Force
```

### Permission Denied

Run PowerShell as Administrator

### Cannot Access from Network

1. Check Windows Firewall
2. Verify you're using `--host 0.0.0.0`
3. Confirm devices are on same network

## 🚀 Advanced Options

### With SSL/HTTPS

```bash
uvicorn main:app --host 0.0.0.0 --port 443 --ssl-keyfile key.pem --ssl-certfile cert.pem
```

### With Custom Log Level

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --log-level debug
```

### With Access Logs

```bash
uvicorn main:app --host 0.0.0.0 --port 8001 --access-log
```

### Background Process (PowerShell)

```powershell
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd C:\safestride\ai_agents; uvicorn main:app --host 0.0.0.0 --port 8001"
```

## 📋 Environment Variables

Create `.env` file in `ai_agents/`:

```env
PORT=8001
HOST=0.0.0.0
RELOAD=false
WORKERS=1
```

Then modify `main.py` to read these:

```python
import os
from dotenv import load_dotenv

load_dotenv()

PORT = int(os.getenv("PORT", 8001))
HOST = os.getenv("HOST", "0.0.0.0")
```

## 🎯 Best Practices

1. **Development:** Use `--reload` for auto-restart on code changes
2. **Testing:** Use `--host 127.0.0.1` for security
3. **Production:** Use `--workers` for better performance
4. **Network Testing:** Use `--host 0.0.0.0` to test from mobile devices
5. **Always:** Set proper CORS headers in FastAPI

## 🔗 Integration with Daily Runner

The daily automation scripts (`daily_runner.py`, `simple_daily_cycle.py`) expect:

- Server running on `http://127.0.0.1:8001`
- Or set `API_BASE_URL` environment variable to match your port

If using different port:

```python
# In daily_runner.py or simple_daily_cycle.py
API_BASE_URL = f"http://127.0.0.1:{os.getenv('PORT', '8001')}"
```

---

**Quick Start:**

```powershell
cd C:\safestride\ai_agents
.\start_server.ps1
```

**Stop Server:** Press `Ctrl+C`
