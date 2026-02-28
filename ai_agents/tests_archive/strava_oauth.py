"""
Strava OAuth 2.0 Authentication Flow
Handles athlete authorization and token management.

Flow:
1. Athlete clicks "Connect with Strava"
2. Redirect to Strava authorization page
3. Strava redirects back with code
4. Exchange code for access token
5. Store token in database
6. Token refresh (automatic)

Required Environment Variables:
- STRAVA_CLIENT_ID
- STRAVA_CLIENT_SECRET
- STRAVA_REDIRECT_URI
"""

import os
import httpx
from datetime import datetime, timedelta
from typing import Dict, Optional
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import RedirectResponse

from database_integration import DatabaseIntegration


class StravaOAuth:
    """Handles Strava OAuth 2.0 flow"""
    
    def __init__(self, database: DatabaseIntegration):
        """Initialize OAuth handler"""
        self.db = database
        
        # Strava OAuth configuration
        self.client_id = os.getenv("STRAVA_CLIENT_ID")
        self.client_secret = os.getenv("STRAVA_CLIENT_SECRET")
        self.redirect_uri = os.getenv("STRAVA_REDIRECT_URI")
        
        if not all([self.client_id, self.client_secret, self.redirect_uri]):
            raise ValueError(
                "STRAVA_CLIENT_ID, STRAVA_CLIENT_SECRET, and STRAVA_REDIRECT_URI "
                "must be set in environment"
            )
        
        # Strava OAuth endpoints
        self.auth_url = "https://www.strava.com/oauth/authorize"
        self.token_url = "https://www.strava.com/oauth/token"
        
        # HTTP client
        self.http_client = httpx.AsyncClient()
    
    def get_authorization_url(
        self,
        athlete_id: str,
        scope: str = "read,activity:read,activity:write"
    ) -> str:
        """
        Generate Strava authorization URL.
        
        Args:
            athlete_id: SafeStride athlete ID (used as state parameter)
            scope: Requested permissions (comma-separated)
                - read: Read public profile
                - activity:read: Read activities
                - activity:write: Create/update activities
        
        Returns:
            Authorization URL to redirect athlete to
        """
        
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "response_type": "code",
            "approval_prompt": "auto",  # Only prompt if not already authorized
            "scope": scope,
            "state": athlete_id  # Pass athlete ID for callback identification
        }
        
        # Build URL
        url = f"{self.auth_url}?"
        url += "&".join([f"{k}={v}" for k, v in params.items()])
        
        return url
    
    async def handle_callback(
        self,
        code: str,
        state: str,  # athlete_id
        scope: Optional[str] = None
    ) -> Dict:
        """
        Handle OAuth callback after athlete authorizes.
        
        Args:
            code: Authorization code from Strava
            state: Athlete ID (from state parameter)
            scope: Granted scopes
        
        Returns:
            Token data with athlete info
        """
        
        athlete_id = state
        
        # Exchange code for access token
        token_data = await self._exchange_code_for_token(code)
        
        # Extract token info
        access_token = token_data['access_token']
        refresh_token = token_data['refresh_token']
        expires_at = token_data['expires_at']
        
        # Get Strava athlete info
        strava_athlete = token_data['athlete']
        strava_athlete_id = strava_athlete['id']
        
        # Store tokens in database
        await self._store_tokens(
            athlete_id=athlete_id,
            strava_athlete_id=strava_athlete_id,
            access_token=access_token,
            refresh_token=refresh_token,
            expires_at=expires_at,
            scopes=scope
        )
        
        return {
            "status": "success",
            "athlete_id": athlete_id,
            "strava_athlete_id": strava_athlete_id,
            "strava_name": f"{strava_athlete['firstname']} {strava_athlete['lastname']}",
            "scopes": scope,
            "message": "Strava connected successfully!"
        }
    
    async def _exchange_code_for_token(self, code: str) -> Dict:
        """Exchange authorization code for access token"""
        
        payload = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "code": code,
            "grant_type": "authorization_code"
        }
        
        try:
            response = await self.http_client.post(self.token_url, json=payload)
            response.raise_for_status()
            return response.json()
        
        except httpx.HTTPStatusError as e:
            error_data = e.response.json() if e.response else {}
            raise HTTPException(
                status_code=e.response.status_code,
                detail=f"Strava token exchange failed: {error_data.get('message', 'Unknown error')}"
            )
    
    async def _store_tokens(
        self,
        athlete_id: str,
        strava_athlete_id: int,
        access_token: str,
        refresh_token: str,
        expires_at: int,
        scopes: Optional[str]
    ):
        """Store Strava tokens in database"""
        
        # Update athlete profile with Strava info
        self.db.update_athlete_profile(
            athlete_id=athlete_id,
            updates={
                "strava_athlete_id": strava_athlete_id,
                "strava_access_token": access_token,
                "strava_refresh_token": refresh_token,
                "strava_token_expires_at": datetime.fromtimestamp(expires_at).isoformat(),
                "strava_scopes": scopes,
                "strava_connected": True,
                "strava_connected_at": datetime.now().isoformat()
            }
        )
    
    async def refresh_access_token(self, athlete_id: str) -> str:
        """
        Refresh expired access token.
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            New access token
        """
        
        # Get current tokens from database
        athlete = self.db.get_athlete_profile(athlete_id)
        if not athlete or not athlete.get('strava_refresh_token'):
            raise ValueError(f"No Strava refresh token for athlete {athlete_id}")
        
        refresh_token = athlete['strava_refresh_token']
        
        # Request new access token
        payload = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "refresh_token": refresh_token,
            "grant_type": "refresh_token"
        }
        
        try:
            response = await self.http_client.post(self.token_url, json=payload)
            response.raise_for_status()
            token_data = response.json()
            
            # Update stored tokens
            new_access_token = token_data['access_token']
            new_refresh_token = token_data.get('refresh_token', refresh_token)
            expires_at = token_data['expires_at']
            
            await self._store_tokens(
                athlete_id=athlete_id,
                strava_athlete_id=athlete['strava_athlete_id'],
                access_token=new_access_token,
                refresh_token=new_refresh_token,
                expires_at=expires_at,
                scopes=athlete.get('strava_scopes')
            )
            
            return new_access_token
        
        except httpx.HTTPStatusError as e:
            error_data = e.response.json() if e.response else {}
            raise HTTPException(
                status_code=e.response.status_code,
                detail=f"Token refresh failed: {error_data.get('message', 'Unknown error')}"
            )
    
    async def get_valid_token(self, athlete_id: str) -> str:
        """
        Get valid access token (refreshing if expired).
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            Valid access token
        """
        
        athlete = self.db.get_athlete_profile(athlete_id)
        if not athlete or not athlete.get('strava_access_token'):
            raise ValueError(f"No Strava connection for athlete {athlete_id}")
        
        # Check if token is expired
        expires_at = datetime.fromisoformat(athlete['strava_token_expires_at'])
        
        if datetime.now() >= expires_at - timedelta(minutes=5):  # Refresh 5 min before expiry
            return await self.refresh_access_token(athlete_id)
        
        return athlete['strava_access_token']
    
    async def disconnect(self, athlete_id: str) -> Dict:
        """
        Disconnect Strava from athlete account.
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            Status message
        """
        
        # Revoke Strava access (deauthorize)
        athlete = self.db.get_athlete_profile(athlete_id)
        if athlete and athlete.get('strava_access_token'):
            try:
                # Revoke token via Strava API
                access_token = athlete['strava_access_token']
                await self.http_client.post(
                    "https://www.strava.com/oauth/deauthorize",
                    headers={"Authorization": f"Bearer {access_token}"}
                )
            except Exception as e:
                print(f"⚠️ Failed to revoke Strava token: {e}")
        
        # Remove tokens from database
        self.db.update_athlete_profile(
            athlete_id=athlete_id,
            updates={
                "strava_athlete_id": None,
                "strava_access_token": None,
                "strava_refresh_token": None,
                "strava_token_expires_at": None,
                "strava_scopes": None,
                "strava_connected": False
            }
        )
        
        return {
            "status": "success",
            "message": "Strava disconnected successfully"
        }


# FastAPI application with OAuth endpoints
app = FastAPI(title="SafeStride Strava OAuth")

# Initialize OAuth handler
db = DatabaseIntegration()
strava_oauth = StravaOAuth(database=db)


@app.get("/strava/connect")
async def connect_strava(athlete_id: str = Query(..., description="SafeStride athlete ID")):
    """
    Initiate Strava connection.
    
    Redirects athlete to Strava authorization page.
    """
    
    # Generate authorization URL
    auth_url = strava_oauth.get_authorization_url(athlete_id)
    
    # Redirect to Strava
    return RedirectResponse(url=auth_url)


@app.get("/strava/callback")
async def strava_callback(
    code: str = Query(..., description="Authorization code"),
    state: str = Query(..., description="Athlete ID"),
    scope: Optional[str] = Query(None, description="Granted scopes")
):
    """
    Handle Strava OAuth callback.
    
    Exchanges code for access token and stores in database.
    """
    
    try:
        result = await strava_oauth.handle_callback(code, state, scope)
        
        # Redirect to success page (customize this URL)
        return {
            "status": "success",
            "message": result['message'],
            "athlete_id": result['athlete_id'],
            "strava_name": result['strava_name']
        }
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.post("/strava/disconnect")
async def disconnect_strava(athlete_id: str):
    """Disconnect Strava from athlete account"""
    
    try:
        result = await strava_oauth.disconnect(athlete_id)
        return result
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/strava/status/{athlete_id}")
async def strava_status(athlete_id: str):
    """Check Strava connection status for athlete"""
    
    try:
        athlete = db.get_athlete_profile(athlete_id)
        
        if not athlete:
            raise HTTPException(status_code=404, detail="Athlete not found")
        
        connected = athlete.get('strava_connected', False)
        
        return {
            "athlete_id": athlete_id,
            "strava_connected": connected,
            "strava_athlete_id": athlete.get('strava_athlete_id'),
            "connected_at": athlete.get('strava_connected_at'),
            "scopes": athlete.get('strava_scopes')
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health_check():
    """Health check"""
    return {
        "status": "healthy",
        "service": "SafeStride Strava OAuth",
        "timestamp": datetime.now().isoformat()
    }


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8002,
        reload=True
    )
