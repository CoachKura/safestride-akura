"""Test if main.py can be imported"""
import sys
sys.path.insert(0, r"c:\safestride\ai_agents")

try:
    print("Importing main...")
    from main import app
    print("✓ Main imported successfully")
    print(f"✓ App type: {type(app)}")
    print(f"✓ App title: {app.title}")
    
    # Try to get the routes
    print(f"✓ Routes count: {len(app.routes)}")
    print("\nAvailable endpoints:")
    for route in app.routes:
        if hasattr(route, 'path') and hasattr(route, 'methods'):
            print(f"  {route.methods} {route.path}")
            
except Exception as e:
    print(f"✗ Error: {e}")
    import traceback
    traceback.print_exc()
