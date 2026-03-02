"""
Environment Configuration Validator
Checks all required environment variables on startup.

Usage:
    from env_validator import validate_environment, get_missing_vars
    
    # On startup
    is_valid, missing = validate_environment()
    if not is_valid:
        raise RuntimeError(f'Missing environment variables: {missing}')
"""

import os
from typing import Dict, List, Tuple
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


# Required environment variables
REQUIRED_VARS = {
    # Supabase
    'SUPABASE_URL': 'Supabase project URL',
    'SUPABASE_SERVICE_ROLE_KEY': 'Supabase service role key (admin access)',
    
    # Strava API
    'STRAVA_CLIENT_ID': 'Strava OAuth client ID',
    'STRAVA_CLIENT_SECRET': 'Strava OAuth client secret',
    
    # Telegram Bot
    'TELEGRAM_TOKEN': 'Telegram bot token',
    
    # JWT Authentication
    'JWT_SECRET': 'JWT signing secret',
}

# Optional but recommended
RECOMMENDED_VARS = {
    'OPENAI_API_KEY': 'OpenAI API key for AI features',
    'SUPABASE_ANON_KEY': 'Supabase anonymous key for client auth',
    'STRAVA_REDIRECT_URI': 'Strava OAuth redirect URI',
    'AISRI_API_URL': 'AISRi API base URL',
}


def validate_environment(verbose: bool = True) -> Tuple[bool, List[str]]:
    """
    Validate all required environment variables are set.
    
    Args:
        verbose: Print validation results
    
    Returns:
        (is_valid, missing_vars)
    """
    
    missing = []
    
    for var_name, description in REQUIRED_VARS.items():
        value = os.getenv(var_name)
        
        if not value or value.strip() == '':
            missing.append(var_name)
            if verbose:
                print(f"? MISSING: {var_name} - {description}")
        else:
            if verbose:
                # Show first/last few chars for security
                if len(value) > 10:
                    masked = f"{value[:4]}...{value[-4:]}"
                else:
                    masked = "***"
                print(f"? {var_name}: {masked}")
    
    is_valid = len(missing) == 0
    
    if verbose:
        print(f"\n{'='*60}")
        if is_valid:
            print("? All required environment variables are set!")
        else:
            print(f"? Missing {len(missing)} required variables:")
            for var in missing:
                print(f"   - {var}: {REQUIRED_VARS[var]}")
        print(f"{'='*60}\n")
    
    return is_valid, missing


def check_recommended_vars(verbose: bool = True) -> List[str]:
    """Check recommended environment variables"""
    
    missing = []
    
    if verbose:
        print("Checking recommended variables...")
    
    for var_name, description in RECOMMENDED_VARS.items():
        value = os.getenv(var_name)
        
        if not value or value.strip() == '':
            missing.append(var_name)
            if verbose:
                print(f"??  RECOMMENDED: {var_name} - {description}")
        else:
            if verbose:
                print(f"? {var_name}: Set")
    
    return missing


def get_missing_vars() -> Dict[str, str]:
    """Get dictionary of missing required variables with descriptions"""
    
    missing = {}
    
    for var_name, description in REQUIRED_VARS.items():
        value = os.getenv(var_name)
        if not value or value.strip() == '':
            missing[var_name] = description
    
    return missing


def validate_supabase_config() -> Tuple[bool, str]:
    """Validate Supabase configuration specifically"""
    
    url = os.getenv('SUPABASE_URL')
    service_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    anon_key = os.getenv('SUPABASE_ANON_KEY')
    
    if not url:
        return False, "SUPABASE_URL is not set"
    
    if not url.startswith('https://'):
        return False, f"SUPABASE_URL must start with https:// (got: {url})"
    
    if not service_key:
        return False, "SUPABASE_SERVICE_ROLE_KEY is not set"
    
    # Check if service key looks like a JWT
    if not service_key.startswith('eyJ'):
        return False, "SUPABASE_SERVICE_ROLE_KEY doesn't look like a valid JWT token"
    
    # Check if anon key is mistakenly used as service key
    if anon_key and service_key == anon_key:
        return False, "SUPABASE_SERVICE_ROLE_KEY is set to ANON_KEY (security risk!)"
    
    return True, "Supabase configuration valid"


def validate_strava_config() -> Tuple[bool, str]:
    """Validate Strava API configuration"""
    
    client_id = os.getenv('STRAVA_CLIENT_ID')
    client_secret = os.getenv('STRAVA_CLIENT_SECRET')
    
    if not client_id:
        return False, "STRAVA_CLIENT_ID is not set"
    
    if not client_secret:
        return False, "STRAVA_CLIENT_SECRET is not set"
    
    # Check if client_id is numeric
    if not client_id.isdigit():
        return False, f"STRAVA_CLIENT_ID should be numeric (got: {client_id})"
    
    # Check if client_secret looks valid (40 chars hex)
    if len(client_secret) != 40:
        return False, f"STRAVA_CLIENT_SECRET should be 40 characters (got: {len(client_secret)})"
    
    return True, "Strava configuration valid"


def print_environment_report():
    """Print comprehensive environment validation report"""
    
    print("\n" + "="*70)
    print("?? ENVIRONMENT CONFIGURATION REPORT")
    print("="*70 + "\n")
    
    # Check required variables
    print("?? REQUIRED VARIABLES:")
    is_valid, missing = validate_environment(verbose=True)
    
    # Check recommended variables
    print("\n?? RECOMMENDED VARIABLES:")
    check_recommended_vars(verbose=True)
    
    # Validate Supabase
    print("\n???  SUPABASE VALIDATION:")
    supabase_valid, supabase_msg = validate_supabase_config()
    print(f"{'?' if supabase_valid else '?'} {supabase_msg}")
    
    # Validate Strava
    print("\n?? STRAVA VALIDATION:")
    strava_valid, strava_msg = validate_strava_config()
    print(f"{'?' if strava_valid else '?'} {strava_msg}")
    
    # Overall status
    print("\n" + "="*70)
    if is_valid and supabase_valid and strava_valid:
        print("? ENVIRONMENT READY FOR PRODUCTION")
    else:
        print("? ENVIRONMENT CONFIGURATION INCOMPLETE")
        print("\n??  FIX REQUIRED BEFORE DEPLOYMENT")
    print("="*70 + "\n")


if __name__ == "__main__":
    # Run validation when executed directly
    print_environment_report()

# Phase 0 Stabilization - Production Services  
try:
    from orchestrator import AISRiOrchestrator
    _ORCHESTRATOR_OK = True
except Exception as e:
    _ORCHESTRATOR_OK = False
    print(f'Orchestrator unavailable: {e}')

try:
    from env_validator import validate_environment
    _ENV_VALIDATOR_OK = True
except:
    _ENV_VALIDATOR_OK = False

try:
    from aisri_safety_gate import AISRISafetyGate
    from strava_oauth_service import StravaOAuthService
    _PHASE0_OK = True
except Exception as e:
    _PHASE0_OK = False
    print(f'Phase 0 services unavailable: {e}')

if _ENV_VALIDATOR_OK:
    try:
        is_valid, missing = validate_environment(verbose=True)
        if not is_valid:
            print(f'WARNING: Missing {len(missing)} variables')
    except: pass

if _ORCHESTRATOR_OK:
    try:
        orchestrator = AISRiOrchestrator()
        print('Orchestrator initialized')
    except Exception as e:
        print(f'Orchestrator init failed: {e}')
        import sys
        sys.exit(1)

