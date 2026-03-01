"""
AISRi-Guardian: Deployment Integrity Gate
Enforces structural discipline and prevents deployment mismatches.

Usage:
    python system_guardian.py --audit  # CLI audit mode
    
    Or import into main.py:
    from system_guardian import run_integrity_checks
    run_integrity_checks()
"""

import os
import sys
from pathlib import Path
from typing import List, Tuple


class SystemIntegrityException(Exception):
    """Raised when system integrity checks fail"""
    pass


class AISRiGuardian:
    """System integrity checker for production deployments"""
    
    def __init__(self, base_dir: str = None):
        """Initialize guardian with base directory"""
        if base_dir is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        self.base_dir = Path(base_dir)
        self.violations = []
        self.warnings = []
        self.passed = []
    
    def check_file_structure(self) -> bool:
        """Check for file structure violations"""
        print("\n" + "=" * 70)
        print("FILE STRUCTURE CHECKS")
        print("=" * 70)
        
        all_passed = True
        
        # Check 1: Only one main.py in production directory
        main_files = list(self.base_dir.glob("main.py"))
        if len(main_files) == 0:
            self.violations.append("❌ CRITICAL: No main.py found in production directory")
            all_passed = False
        elif len(main_files) > 1:
            self.violations.append(f"❌ CRITICAL: Multiple main.py files found: {[str(f) for f in main_files]}")
            all_passed = False
        else:
            self.passed.append(f"✅ Single main.py found: {main_files[0]}")
        
        # Check 2: No backup files
        backup_files = list(self.base_dir.glob("*.backup")) + list(self.base_dir.glob("*_backup.py"))
        if backup_files:
            self.warnings.append(f"⚠️  WARNING: Backup files found: {[f.name for f in backup_files]}")
        else:
            self.passed.append("✅ No backup files in production directory")
        
        # Check 3: No integration step files
        integrate_files = list(self.base_dir.glob("integrate_step*.py")) + list(self.base_dir.glob("integrate_*.py"))
        if integrate_files:
            self.warnings.append(f"⚠️  WARNING: Integration step files found: {[f.name for f in integrate_files]}")
        else:
            self.passed.append("✅ No integration step files in production directory")
        
        # Check 4: No duplicate main.py in nested directories
        nested_mains = []
        for subdir in self.base_dir.iterdir():
            if subdir.is_dir() and not subdir.name.startswith('.'):
                nested = list(subdir.glob("main.py"))
                if nested:
                    nested_mains.extend(nested)
        
        if nested_mains:
            self.warnings.append(f"⚠️  WARNING: Found main.py in subdirectories: {[str(f.relative_to(self.base_dir)) for f in nested_mains]}")
            self.warnings.append("    This can cause deployment confusion if root directory is misconfigured")
        else:
            self.passed.append("✅ No duplicate main.py files in subdirectories")
        
        return all_passed
    
    def check_router_integrity(self) -> bool:
        """Check router registration and imports"""
        print("\n" + "=" * 70)
        print("ROUTER INTEGRITY CHECKS")
        print("=" * 70)
        
        all_passed = True
        main_file = self.base_dir / "main.py"
        
        if not main_file.exists():
            self.violations.append("❌ CRITICAL: main.py not found, cannot check routers")
            return False
        
        try:
            with open(main_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Check 1: Orchestrator imported
            if "from orchestrator import" in content:
                self.passed.append("✅ Orchestrator imported")
            else:
                self.violations.append("❌ CRITICAL: Orchestrator not imported in main.py")
                all_passed = False
            
            # Check 2: /strava/connect route exists
            if "@app.get('/strava/connect')" in content or '@app.get("/strava/connect")' in content:
                self.passed.append("✅ /strava/connect route defined")
            else:
                self.violations.append("❌ CRITICAL: /strava/connect route not found in main.py")
                all_passed = False
            
            # Check 3: /strava/callback route exists
            if "@app.get('/strava/callback')" in content or '@app.get("/strava/callback")' in content:
                self.passed.append("✅ /strava/callback route defined")
            else:
                self.violations.append("❌ CRITICAL: /strava/callback route not found in main.py")
                all_passed = False
            
            # Check 4: /strava/status route exists
            if "/strava/status" in content:
                self.passed.append("✅ /strava/status route defined")
            else:
                self.warnings.append("⚠️  WARNING: /strava/status route not found")
            
            # Check 5: /strava/disconnect route exists
            if "/strava/disconnect" in content:
                self.passed.append("✅ /strava/disconnect route defined")
            else:
                self.warnings.append("⚠️  WARNING: /strava/disconnect route not found")
            
            # Check 6: Check for duplicate route definitions
            strava_routes = content.count("@app.get('/strava/connect')")
            if strava_routes > 1:
                self.violations.append(f"❌ CRITICAL: Duplicate /strava/connect definitions found ({strava_routes} times)")
                all_passed = False
            
            # Check 7: FastAPI app instance exists
            if "app = FastAPI(" in content:
                self.passed.append("✅ FastAPI app instance created")
            else:
                self.violations.append("❌ CRITICAL: FastAPI app instance not found")
                all_passed = False
            
            # Check 8: Orchestrator initialized
            if "orchestrator = AISRiOrchestrator()" in content or "@app.on_event('startup')" in content:
                self.passed.append("✅ Orchestrator initialization found")
            else:
                self.warnings.append("⚠️  WARNING: Orchestrator initialization not clearly visible")
            
        except Exception as e:
            self.violations.append(f"❌ CRITICAL: Failed to read main.py: {e}")
            all_passed = False
        
        return all_passed
    
    def check_environment(self) -> bool:
        """Check required environment variables"""
        print("\n" + "=" * 70)
        print("ENVIRONMENT VARIABLE CHECKS")
        print("=" * 70)
        
        all_passed = True
        
        required_vars = [
            ("STRAVA_CLIENT_ID", "Strava OAuth authentication"),
            ("STRAVA_CLIENT_SECRET", "Strava OAuth authentication"),
            ("STRAVA_REDIRECT_URI", "Strava OAuth callback"),
            ("SUPABASE_URL", "Database connection"),
            ("SUPABASE_SERVICE_ROLE_KEY", "Database admin access"),
            ("OPENAI_API_KEY", "AI agent functionality"),
        ]
        
        for var_name, description in required_vars:
            value = os.getenv(var_name)
            if value:
                # Mask sensitive values
                if "SECRET" in var_name or "KEY" in var_name:
                    masked = value[:8] + "..." if len(value) > 8 else "***"
                    self.passed.append(f"✅ {var_name} = {masked} ({description})")
                else:
                    self.passed.append(f"✅ {var_name} = {value} ({description})")
            else:
                self.violations.append(f"❌ CRITICAL: {var_name} not set ({description})")
                all_passed = False
        
        # Optional but recommended
        optional_vars = [
            ("SUPABASE_SERVICE_KEY", "Alternate database key name"),
            ("PORT", "Server port (default: 8000)"),
        ]
        
        for var_name, description in optional_vars:
            value = os.getenv(var_name)
            if value:
                self.passed.append(f"✅ {var_name} set ({description})")
            else:
                self.warnings.append(f"⚠️  INFO: {var_name} not set ({description})")
        
        return all_passed
    
    def check_dependencies(self) -> bool:
        """Check key Python imports are available"""
        print("\n" + "=" * 70)
        print("DEPENDENCY CHECKS")
        print("=" * 70)
        
        all_passed = True
        
        required_modules = [
            ("fastapi", "FastAPI framework"),
            ("uvicorn", "ASGI server"),
            ("supabase", "Supabase client"),
            ("httpx", "HTTP client for OAuth"),
            ("pydantic", "Data validation"),
        ]
        
        for module_name, description in required_modules:
            try:
                __import__(module_name)
                self.passed.append(f"✅ {module_name} available ({description})")
            except ImportError:
                self.violations.append(f"❌ CRITICAL: {module_name} not installed ({description})")
                all_passed = False
        
        # Check for orchestrator module
        orchestrator_file = self.base_dir / "orchestrator.py"
        if orchestrator_file.exists():
            self.passed.append("✅ orchestrator.py exists")
        else:
            self.violations.append("❌ CRITICAL: orchestrator.py not found")
            all_passed = False
        
        # Check for strava_oauth_service module
        oauth_file = self.base_dir / "strava_oauth_service.py"
        if oauth_file.exists():
            self.passed.append("✅ strava_oauth_service.py exists")
        else:
            self.violations.append("❌ CRITICAL: strava_oauth_service.py not found")
            all_passed = False
        
        return all_passed
    
    def print_report(self):
        """Print detailed integrity report"""
        print("\n" + "=" * 70)
        print("INTEGRITY REPORT SUMMARY")
        print("=" * 70)
        
        if self.passed:
            print(f"\n✅ PASSED CHECKS ({len(self.passed)}):")
            for check in self.passed:
                print(f"   {check}")
        
        if self.warnings:
            print(f"\n⚠️  WARNINGS ({len(self.warnings)}):")
            for warning in self.warnings:
                print(f"   {warning}")
        
        if self.violations:
            print(f"\n❌ CRITICAL VIOLATIONS ({len(self.violations)}):")
            for violation in self.violations:
                print(f"   {violation}")
        
        print("\n" + "=" * 70)
        
        if self.violations:
            print("❌ INTEGRITY CHECK FAILED")
            print("=" * 70)
            return False
        elif self.warnings:
            print("⚠️  INTEGRITY CHECK PASSED WITH WARNINGS")
            print("=" * 70)
            return True
        else:
            print("✅ ALL INTEGRITY CHECKS PASSED")
            print("=" * 70)
            return True
    
    def run_all_checks(self, strict: bool = True) -> bool:
        """Run all integrity checks"""
        print("\n" + "=" * 70)
        print("AISRi-GUARDIAN: DEPLOYMENT INTEGRITY GATE")
        print("=" * 70)
        print(f"Base Directory: {self.base_dir}")
        print(f"Strict Mode: {strict}")
        
        file_ok = self.check_file_structure()
        router_ok = self.check_router_integrity()
        env_ok = self.check_environment()
        deps_ok = self.check_dependencies()
        
        self.print_report()
        
        if strict:
            # In strict mode, any violation fails
            return file_ok and router_ok and env_ok and deps_ok
        else:
            # In non-strict mode, only critical violations fail, warnings are OK
            return len(self.violations) == 0


def run_integrity_checks(strict: bool = False, base_dir: str = None):
    """
    Run integrity checks and raise exception if they fail.
    
    Args:
        strict: If True, warnings also cause failure
        base_dir: Base directory to check (default: current file's directory)
    
    Raises:
        SystemIntegrityException: If integrity checks fail
    """
    guardian = AISRiGuardian(base_dir=base_dir)
    passed = guardian.run_all_checks(strict=strict)
    
    if not passed:
        raise SystemIntegrityException(
            f"System integrity checks failed: {len(guardian.violations)} violations found"
        )
    
    return True


def main():
    """CLI entry point for audit mode"""
    import argparse
    
    parser = argparse.ArgumentParser(description="AISRi-Guardian: Deployment Integrity Gate")
    parser.add_argument("--audit", action="store_true", help="Run audit checks")
    parser.add_argument("--strict", action="store_true", help="Strict mode (warnings cause failure)")
    parser.add_argument("--dir", type=str, help="Base directory to check")
    
    args = parser.parse_args()
    
    if not args.audit:
        parser.print_help()
        sys.exit(0)
    
    try:
        guardian = AISRiGuardian(base_dir=args.dir)
        passed = guardian.run_all_checks(strict=args.strict)
        
        if passed:
            sys.exit(0)
        else:
            sys.exit(1)
    
    except Exception as e:
        print(f"\n❌ GUARDIAN ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
