"""
AISRi API Handler V2
Async HTTP client with retry logic for AISRi AI Engine endpoints
"""

import os
import httpx
import asyncio

AISRI_API_BASE = os.getenv("AISRI_API_BASE", "https://api.akura.in")

class AISRiAPI:
    """Async API client for AISRi AI Engine with intelligent retry logic"""

    @staticmethod
    async def call_endpoint(endpoint: str, payload: dict):
        """
        Call AISRi API endpoint with exponential backoff retry
        
        Args:
            endpoint: API endpoint path (e.g., "/agent/autonomous-decision")
            payload: JSON payload to send
            
        Returns:
            dict: API response or error dict
        """
        retries = 3
        backoff = 2

        for attempt in range(retries):
            try:
                async with httpx.AsyncClient(timeout=30) as client:
                    response = await client.post(
                        f"{AISRI_API_BASE}{endpoint}",
                        json=payload
                    )
                    response.raise_for_status()
                    return response.json()
            except Exception as e:
                if attempt == retries - 1:
                    return {"error": str(e), "endpoint": endpoint}
                await asyncio.sleep(backoff ** attempt)

    @staticmethod
    async def autonomous(payload):
        """Call autonomous decision endpoint"""
        return await AISRiAPI.call_endpoint("/agent/autonomous-decision", payload)

    @staticmethod
    async def injury(payload):
        """Call injury risk prediction endpoint"""
        return await AISRiAPI.call_endpoint("/agent/predict-injury-risk", payload)

    @staticmethod
    async def training(payload):
        """Call training plan generation endpoint"""
        return await AISRiAPI.call_endpoint("/agent/generate-training-plan", payload)

    @staticmethod
    async def performance(payload):
        """Call performance prediction endpoint"""
        return await AISRiAPI.call_endpoint("/agent/predict-performance", payload)
