"""
Start FastAPI Server for Production

Uses uvicorn with proper host binding and environment-based port.
"""
import os
import subprocess

# Default port
PORT = os.getenv("PORT", "8001")

# Start uvicorn
cmd = f"uvicorn main:app --host 0.0.0.0 --port {PORT}"

print(f"🚀 Starting FastAPI server on port {PORT}...")
print(f"📡 Accessible at: http://localhost:{PORT}")
print(f"🌍 External access: http://0.0.0.0:{PORT}")
print(f"\n💡 Press Ctrl+C to stop\n")

subprocess.run(cmd, shell=True)
