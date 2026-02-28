"""Simple test API to verify FastAPI is working"""
from fastapi import FastAPI
import uvicorn

app = FastAPI(title="SafeStride Test API")

@app.get("/")
def root():
    return {"status": "API is running!", "message": "FastAPI server is working correctly"}

@app.get("/health")
def health():
    return {"status": "healthy"}

if __name__ == "__main__":
    print("Starting test API server on http://localhost:8001")
    print("Visit http://localhost:8001 to test")
    uvicorn.run(app, host="0.0.0.0", port=8001)
