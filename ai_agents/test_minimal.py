"""Minimal FastAPI test"""
import uvicorn
from fastapi import FastAPI

app = FastAPI(title="Test")

@app.get("/")
def root():
    return {"status": "ok", "message": "Test server working"}

if __name__ == "__main__":
    uvicorn.run("test_minimal:app", host="0.0.0.0", port=8000, reload=False)
