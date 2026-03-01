"""
Strava OAuth 2.0 Service (Production)
Handles athlete authorization, token management, and automatic refresh.

Flow:
1. Athlete clicks 'Connect with Strava'
2. Redirect to Strava authorization page
3. Strava redirects back with code
4. Exchange code for access token
5. Store tokens in database (strava_connections table)
6. Auto-refresh tokens before expiry

Required Environment Variables:
- STRAVA_CLIENT_ID
- STRAVA_CLIENT_SECRET
"""

import os
import httpx
from datetime import datetime, timedelta
from typing import Dict, Optional
from fastapi import HTTPException

from database_integration import DatabaseIntegration


class StravaOAuthService:
    """Production Strava OAuth 2.0 handler with automatic token refresh"""
    
    def __init__(self, database: DatabaseIntegration):
        """Initialize OAuth service"""
        self.db = database
        
        # Strava OAuth configuration
        self.client_id = os.getenv("STRAVA_CLIENT_ID")
        self.client_secret = os.getenv("STRAVA_CLIENT_SECRET")
        self.redirect_uri = os.getenv("STRAVA_REDIRECT_URI", "https://api.akura.in/strava/callback")
        
        if not all([self.client_id, self.client_secret]):
            raise ValueError("STRAVA_CLIENT_ID and STRAVA_CLIENT_SECRET must be set")
        
        # Strava OAuth endpoints
        self.auth_url = "https://www.strava.com/oauth/authorize"
        self.token_url = "https://www.strava.com/oauth/token"
        
        # HTTP client for API calls
        self.http_client = httpx.AsyncClient(timeout=30.0)
    
    def get_authorization_url(
        self,
        athlete_id: str,
        scope: str = "read,activity:read_all,activity:write"
    ) -> str:
        """
        Generate Strava authorization URL.
        
        Args:
            athlete_id: SafeStride athlete ID (passed as state)
            scope: Requested permissions
        
        Returns:
            Strava authorization URL
        """
        
        params = {
            "client_id": self.client_id,
            "redirect_uri": self.redirect_uri,
            "response_type": "code",
            "approval_prompt": "auto",
            "scope": scope,
            "state": athlete_id  # Pass athlete_id for callback
        }
        
        query_string = "&".join([f"{k}={v}" for k, v in params.items()])
        return f"{self.auth_url}?{query_string}"
    
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
        
        # Store tokens in strava_connections table
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
            "strava_name": f"{strava_athlete.get('firstname', '')} {strava_athlete.get('lastname', '')}",
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
            error_data = e.response.json() if e.response.text else {}
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
        """Store Strava tokens in strava_connections table"""
        
        # Use supabase client directly for upsert
        try:
            expires_datetime = datetime.fromtimestamp(expires_at)
            
            connection_data = {
                "athlete_id": athlete_id,
                "strava_athlete_id": strava_athlete_id,
                "access_token": access_token,
                "refresh_token": refresh_token,
                "expires_at": expires_datetime.isoformat(),
                "scopes": scopes,
                "connected": True,
                "updated_at": datetime.now().isoformat()
            }
            
            # Upsert to strava_connections table
            result = self.db.supabase.table("strava_connections").upsert(
                connection_data,
                on_conflict="athlete_id"
            ).execute()
            
            print(f"✅ Stored Strava tokens for athlete {athlete_id}")
            
        except Exception as e:
            print(f"❌ Error storing tokens: {e}")
            raise HTTPException(status_code=500, detail=f"Failed to store tokens: {str(e)}")
    
    async def refresh_access_token(self, athlete_id: str) -> str:
        """
        Refresh expired access token.
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            New access token
        """
        
        # Get current tokens from strava_connections
        try:
            result = self.db.supabase.table("strava_connections").select("*").eq(
                "athlete_id", athlete_id
            ).execute()
            
            if not result.data or len(result.data) == 0:
                raise ValueError(f"No Strava connection found for athlete {athlete_id}")
            
            connection = result.data[0]
            refresh_token = connection.get('refresh_token')
            
            if not refresh_token:
                raise ValueError(f"No refresh token for athlete {athlete_id}")
        
        except Exception as e:
            raise ValueError(f"Failed to get refresh token: {str(e)}")
        
        # Request new access token from Strava
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
                strava_athlete_id=connection['strava_athlete_id'],
                access_token=new_access_token,
                refresh_token=new_refresh_token,
                expires_at=expires_at,
                scopes=connection.get('scopes')
            )
            
            print(f"✅ Refreshed Strava token for athlete {athlete_id}")
            return new_access_token
        
        except httpx.HTTPStatusError as e:
            error_data = e.response.json() if e.response.text else {}
            raise HTTPException(
                status_code=e.response.status_code,
                detail=f"Token refresh failed: {error_data.get('message', 'Unknown error')}"
            )
    
    async def get_valid_token(self, athlete_id: str) -> str:
        """
        Get valid access token (auto-refresh if expired).
        
        This is the primary method to use when making Strava API calls.
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            Valid access token
        """
        
        try:
            result = self.db.supabase.table("strava_connections").select("*").eq(
                "athlete_id", athlete_id
            ).execute()
            
            if not result.data or len(result.data) == 0:
                raise ValueError(f"No Strava connection for athlete {athlete_id}")
            
            connection = result.data[0]
            access_token = connection.get('access_token')
            expires_at_str = connection.get('expires_at')
            
            if not access_token or not expires_at_str:
                raise ValueError(f"Invalid token data for athlete {athlete_id}")
            
            # Parse expiration timestamp
            expires_at = datetime.fromisoformat(expires_at_str.replace('Z', '+00:00'))
            
            # Refresh if token expires in less than 5 minutes
            if datetime.now(expires_at.tzinfo) >= expires_at - timedelta(minutes=5):
                print(f"🔄 Token expiring soon for athlete {athlete_id}, refreshing...")
                return await self.refresh_access_token(athlete_id)
            
            return access_token
        
        except Exception as e:
            raise ValueError(f"Failed to get valid token: {str(e)}")
    
    async def disconnect(self, athlete_id: str) -> Dict:
        """
        Disconnect Strava from athlete account.
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            Status message
        """
        
        try:
            # Get connection to revoke token
            result = self.db.supabase.table("strava_connections").select("*").eq(
                "athlete_id", athlete_id
            ).execute()
            
            if result.data and len(result.data) > 0:
                connection = result.data[0]
                access_token = connection.get('access_token')
                
                # Revoke token via Strava API
                if access_token:
                    try:
                        await self.http_client.post(
                            "https://www.strava.com/oauth/deauthorize",
                            headers={"Authorization": f"Bearer {access_token}"}
                        )
                    except Exception as e:
                        print(f"⚠️ Failed to revoke Strava token: {e}")
            
            # Delete connection from database
            self.db.supabase.table("strava_connections").delete().eq(
                "athlete_id", athlete_id
            ).execute()
            
            print(f"✅ Disconnected Strava for athlete {athlete_id}")
            
            return {
                "status": "success",
                "message": "Strava disconnected successfully"
            }
        
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Failed to disconnect: {str(e)}")
    
    async def get_connection_status(self, athlete_id: str) -> Dict:
        """
        Get Strava connection status for athlete.
        
        Args:
            athlete_id: SafeStride athlete ID
        
        Returns:
            Connection status with details
        """
        
        try:
            result = self.db.supabase.table("strava_connections").select("*").eq(
                "athlete_id", athlete_id
            ).execute()
            
            if not result.data or len(result.data) == 0:
                return {
                    "connected": False,
                    "message": "Not connected to Strava"
                }
            
            connection = result.data[0]
            expires_at = datetime.fromisoformat(connection['expires_at'].replace('Z', '+00:00'))
            
            return {
                "connected": True,
                "strava_athlete_id": connection['strava_athlete_id'],
                "scopes": connection.get('scopes'),
                "expires_at": connection['expires_at'],
                "expires_in_hours": (expires_at - datetime.now(expires_at.tzinfo)).total_seconds() / 3600,
                "updated_at": connection.get('updated_at')
            }
        
        except Exception as e:
            return {
                "connected": False,
                "error": str(e)
            }
