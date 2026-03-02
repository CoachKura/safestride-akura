"""
Strava Webhook Subscription Verification
Checks and configures Strava webhook subscription.

Strava Webhooks allow real-time activity updates without polling.

Setup Steps:
1. Create webhook subscription with Strava API
2. Verify webhook endpoint responds correctly
3. Handle webhook events in production
"""

import os
import httpx
from typing import Dict
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

def get_strava_config() -> Dict:
    '''Get Strava API configuration'''
    return {
        'client_id': os.getenv('STRAVA_CLIENT_ID'),
        'client_secret': os.getenv('STRAVA_CLIENT_SECRET'),
        'callback_url': os.getenv('STRAVA_REDIRECT_URI', 'https://api.akura.in/webhooks/strava'),
        'verify_token': os.getenv('STRAVA_VERIFY_TOKEN', 'SAFESTRIDE_VERIFY')
    }


async def list_subscriptions() -> Dict:
    '''List current Strava webhook subscriptions'''
    
    config = get_strava_config()
    
    if not config['client_id'] or not config['client_secret']:
        return {
            'error': 'STRAVA_CLIENT_ID or STRAVA_CLIENT_SECRET not set',
            'subscriptions': []
        }
    
    url = 'https://www.strava.com/api/v3/push_subscriptions'
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                url,
                params={
                    'client_id': config['client_id'],
                    'client_secret': config['client_secret']
                }
            )
            response.raise_for_status()
            
            subscriptions = response.json()
            
            return {
                'status': 'success',
                'count': len(subscriptions),
                'subscriptions': subscriptions
            }
        
        except httpx.HTTPStatusError as e:
            return {
                'status': 'error',
                'message': f'HTTP {e.response.status_code}: {e.response.text}',
                'subscriptions': []
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': str(e),
                'subscriptions': []
            }


async def create_subscription(callback_url: str) -> Dict:
    '''
    Create new Strava webhook subscription.
    
    Args:
        callback_url: Public webhook endpoint URL
    
    Returns:
        Subscription details or error
    '''
    
    config = get_strava_config()
    
    if not config['client_id'] or not config['client_secret']:
        return {'error': 'Strava credentials not configured'}
    
    url = 'https://www.strava.com/api/v3/push_subscriptions'
    
    payload = {
        'client_id': config['client_id'],
        'client_secret': config['client_secret'],
        'callback_url': callback_url,
        'verify_token': config['verify_token']
    }
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(url, data=payload)
            response.raise_for_status()
            
            result = response.json()
            
            return {
                'status': 'success',
                'subscription_id': result.get('id'),
                'details': result
            }
        
        except httpx.HTTPStatusError as e:
            error_data = e.response.json() if e.response.text else {}
            return {
                'status': 'error',
                'message': error_data.get('message', e.response.text),
                'code': e.response.status_code
            }
        except Exception as e:
            return {
                'status': 'error',
                'message': str(e)
            }


async def delete_subscription(subscription_id: int) -> Dict:
    '''Delete a Strava webhook subscription'''
    
    config = get_strava_config()
    
    url = f'https://www.strava.com/api/v3/push_subscriptions/{subscription_id}'
    
    async with httpx.AsyncClient() as client:
        try:
            response = await client.delete(
                url,
                params={
                    'client_id': config['client_id'],
                    'client_secret': config['client_secret']
                }
            )
            response.raise_for_status()
            
            return {
                'status': 'success',
                'message': f'Subscription {subscription_id} deleted'
            }
        
        except httpx.HTTPStatusError as e:
            return {
                'status': 'error',
                'message': e.response.text
            }


async def verify_webhook_endpoint(callback_url: str) -> Dict:
    '''
    Verify webhook endpoint is accessible.
    Strava will send GET request with hub.challenge parameter.
    '''
    
    async with httpx.AsyncClient() as client:
        try:
            # Test if endpoint is reachable
            response = await client.get(callback_url, timeout=10)
            
            return {
                'status': 'reachable',
                'status_code': response.status_code,
                'message': 'Endpoint is accessible'
            }
        
        except Exception as e:
            return {
                'status': 'unreachable',
                'error': str(e),
                'message': 'Endpoint cannot be reached - check URL and firewall'
            }


async def check_webhook_status() -> Dict:
    '''
    Comprehensive webhook status check.
    
    Returns:
        Status report with recommendations
    '''
    
    print('\n' + '='*70)
    print('?? STRAVA WEBHOOK STATUS CHECK')
    print('='*70 + '\n')
    
    config = get_strava_config()
    
    # Check configuration
    print('?? Configuration:')
    print(f'   Client ID: {config['client_id'] or 'NOT SET'}')
    print(f'   Client Secret: {'Set' if config['client_secret'] else 'NOT SET'}')
    print(f'   Callback URL: {config['callback_url']}')
    print(f'   Verify Token: {config['verify_token']}\n')
    
    if not config['client_id'] or not config['client_secret']:
        print('? Strava credentials not configured in .env')
        return {'status': 'not_configured'}
    
    # Check subscriptions
    print('?? Checking subscriptions...')
    subs_result = await list_subscriptions()
    
    if subs_result['status'] == 'error':
        print(f'? Error: {subs_result['message']}\n')
        return subs_result
    
    subscriptions = subs_result.get('subscriptions', [])
    
    if len(subscriptions) == 0:
        print('??  No active webhook subscriptions found')
        print(f'\n?? To create subscription, run:')
        print(f'   POST https://www.strava.com/api/v3/push_subscriptions')
        print(f'   Body: {{\n     "client_id": "{config['client_id']}",')
        print(f'     "client_secret": "***",')
        print(f'     "callback_url": "{config['callback_url']}",')
        print(f'     "verify_token": "{config['verify_token']}"\n   }}\n')
        
        return {
            'status': 'no_subscription',
            'recommendation': 'Create webhook subscription'
        }
    
    print(f'? Found {len(subscriptions)} subscription(s):\n')
    
    for sub in subscriptions:
        print(f'   ID: {sub.get('id')}')
        print(f'   Callback URL: {sub.get('callback_url')}')
        print(f'   Created: {sub.get('created_at')}')
        print()
    
    # Verify endpoint accessibility
    print('?? Verifying webhook endpoint...')
    verify_result = await verify_webhook_endpoint(config['callback_url'])
    
    if verify_result['status'] == 'reachable':
        print(f'? Endpoint is reachable (HTTP {verify_result['status_code']})\n')
    else:
        print(f'? Endpoint unreachable: {verify_result['error']}\n')
    
    print('='*70)
    print('? WEBHOOK STATUS CHECK COMPLETE')
    print('='*70 + '\n')
    
    return {
        'status': 'active',
        'subscriptions': subscriptions,
        'endpoint_status': verify_result
    }


if __name__ == '__main__':
    import asyncio
    asyncio.run(check_webhook_status())
