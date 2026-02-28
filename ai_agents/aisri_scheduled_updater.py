"""
Scheduled AISRI Score Updater
Runs weekly to automatically calculate/update AISRI scores for all athletes
with connected Strava/Garmin accounts.

Schedule: Every Sunday at 2:00 AM
Purpose: Keep scores fresh without manual intervention

Features:
- Batch processing of all athletes
- Incremental updates (only athletes with new activities)
- Error resilience (continues even if one athlete fails)
- Detailed logging
- Notification on completion

Usage:
    # Run manually for testing
    python aisri_scheduled_updater.py
    
    # Or set up as cron job (Linux/Mac):
    0 2 * * 0 cd /path/to/ai_agents && python aisri_scheduled_updater.py
    
    # Or use Windows Task Scheduler (Windows)
"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import List, Dict
import os
import sys

from database_integration import DatabaseIntegration
from aisri_auto_calculator import AISRIAutoCalculator
from communication_agent_v2 import CommunicationAgent


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/aisri_scheduler.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class AISRIScheduledUpdater:
    """
    Scheduled service to automatically update AISRI scores.
    """
    
    def __init__(self):
        self.db = DatabaseIntegration()
        self.comm = CommunicationAgent()
    
    async def run_weekly_update(self):
        """
        Main entry point for weekly AISRI score updates.
        
        Process:
        1. Fetch all athletes with Strava/Garmin connections
        2. Check for new activities since last calculation
        3. Recalculate AISRI scores for athletes with updates
        4. Send notification summaries
        5. Log results
        """
        
        logger.info("🚀 Starting weekly AISRI score update...")
        start_time = datetime.now()
        
        # Get all athletes with activity connections
        athletes = await self._get_connected_athletes()
        logger.info(f"📊 Found {len(athletes)} athletes with activity connections")
        
        results = {
            'success': 0,
            'skipped': 0,
            'failed': 0,
            'errors': []
        }
        
        # Process each athlete
        for athlete in athletes:
            try:
                updated = await self._update_athlete_aisri(athlete)
                if updated:
                    results['success'] += 1
                else:
                    results['skipped'] += 1
                    
            except Exception as e:
                results['failed'] += 1
                results['errors'].append({
                    'user_id': athlete['user_id'],
                    'error': str(e)
                })
                logger.error(f"❌ Failed to update athlete {athlete['user_id']}: {e}")
        
        # Calculate duration
        duration = (datetime.now() - start_time).total_seconds()
        
        # Log summary
        logger.info(f"""
        ✅ Weekly AISRI update completed!
        
        📈 Results:
        - ✅ Successfully updated: {results['success']}
        - ⏭️  Skipped (no new data): {results['skipped']}
        - ❌ Failed: {results['failed']}
        - ⏱️  Duration: {duration:.1f}s
        """)
        
        # Send admin notification if enabled
        if os.getenv('AISRI_SCHEDULER_NOTIFY', 'true').lower() == 'true':
            await self._send_admin_notification(results, duration)
        
        return results
    
    async def _get_connected_athletes(self) -> List[Dict]:
        """
        Fetch all athletes with Strava or Garmin connections.
        
        Returns:
            List of athlete records with connection info
        """
        query = """
        SELECT 
            u.id as user_id,
            u.email,
            sa.strava_athlete_id,
            sa.last_sync_at as strava_last_sync,
            ga.garmin_user_id,
            ga.last_sync_at as garmin_last_sync
        FROM auth.users u
        LEFT JOIN strava_athletes sa ON u.id = sa.user_id
        LEFT JOIN garmin_connections ga ON u.id = ga.user_id
        WHERE sa.strava_athlete_id IS NOT NULL 
           OR ga.garmin_user_id IS NOT NULL
        """
        
        result = await self.db.supabase.rpc('execute_raw_sql', {'query': query})
        return result.data if result.data else []
    
    async def _update_athlete_aisri(self, athlete: Dict) -> bool:
        """
        Update AISRI score for a single athlete if new activities exist.
        
        Args:
            athlete: Athlete record with connection info
            
        Returns:
            True if updated, False if skipped
        """
        user_id = athlete['user_id']
        
        # Check last AISRI calculation date
        last_calculation = await self.db.get_last_aisri_calculation(user_id)
        
        if last_calculation:
            last_calc_date = datetime.fromisoformat(last_calculation['calculated_at'])
        else:
            last_calc_date = datetime.now() - timedelta(days=365)  # Far in past
        
        # Check for new activities since last calculation
        has_new_activities = await self._has_new_activities_since(
            athlete=athlete,
            since_date=last_calc_date
        )
        
        if not has_new_activities:
            logger.info(f"⏭️  Skipping {user_id}: No new activities since {last_calc_date.date()}")
            return False
        
        # Calculate new AISRI scores
        logger.info(f"🔄 Updating AISRI for {user_id}...")
        
        if athlete.get('strava_athlete_id'):
            result = await AISRIAutoCalculator.calculate_from_strava(
                user_id=user_id,
                strava_athlete_id=athlete['strava_athlete_id']
            )
        else:
            # Future: Add Garmin calculation
            logger.warning(f"⚠️  Garmin-only athletes not yet supported for {user_id}")
            return False
        
        # Save to database
        await self.db.upsert_aisri_score(
            user_id=user_id,
            aisri_score=result.aisri_score,
            risk_level=result.risk_level,
            pillar_adaptability=result.pillar_adaptability,
            pillar_injury_risk=result.pillar_injury_risk,
            pillar_fatigue=result.pillar_fatigue,
            pillar_recovery=result.pillar_recovery,
            pillar_intensity=result.pillar_intensity,
            pillar_consistency=result.pillar_consistency,
            calculation_method=result.calculation_method,
            confidence=result.confidence,
            data_source=result.data_source,
            notes=result.notes
        )
        
        logger.info(f"✅ Updated {user_id}: AISRI={result.aisri_score}, Confidence={result.confidence}%")
        
        # Send notification to athlete if score changed significantly
        if last_calculation:
            score_change = abs(result.aisri_score - last_calculation['aisri_score'])
            if score_change >= 10:
                await self._notify_athlete_score_change(
                    user_id=user_id,
                    old_score=last_calculation['aisri_score'],
                    new_score=result.aisri_score,
                    risk_level=result.risk_level
                )
        
        return True
    
    async def _has_new_activities_since(
        self,
        athlete: Dict,
        since_date: datetime
    ) -> bool:
        """
        Check if athlete has new activities since given date.
        
        Args:
            athlete: Athlete record
            since_date: Check for activities after this date
            
        Returns:
            True if new activities exist
        """
        if athlete.get('strava_athlete_id'):
            activities = await self.db.get_athlete_activities(
                athlete['strava_athlete_id'],
                start_date=since_date
            )
            return len(activities) > 0
        
        # Future: Check Garmin activities
        return False
    
    async def _notify_athlete_score_change(
        self,
        user_id: str,
        old_score: int,
        new_score: int,
        risk_level: str
    ):
        """
        Notify athlete of significant AISRI score change.
        
        Args:
            user_id: User ID
            old_score: Previous AISRI score
            new_score: New AISRI score
            risk_level: Current risk level
        """
        
        change = new_score - old_score
        direction = "increased" if change > 0 else "decreased"
        emoji = "📈" if change > 0 else "📉"
        
        message = f"""
        {emoji} AISRI Score Update
        
        Your weekly AISRI score has been updated:
        
        Previous: {old_score}
        Current: {new_score}
        Change: {change:+d} points
        
        Your current risk level is: {risk_level}
        
        {"Great work! Your training adaptations are improving." if change > 0 else "Your score has decreased. Consider reviewing your training load and recovery."}
        
        View your full analysis in the SafeStride app.
        """
        
        try:
            # Send via Telegram if configured
            if os.getenv('ENABLE_TELEGRAM_NOTIFICATIONS', 'false').lower() == 'true':
                await self.comm.send_telegram_alert(
                    user_id=user_id,
                    message=message,
                    priority='medium'
                )
        except Exception as e:
            logger.warning(f"Failed to send notification to {user_id}: {e}")
    
    async def _send_admin_notification(
        self,
        results: Dict,
        duration: float
    ):
        """
        Send summary notification to admin.
        
        Args:
            results: Update results dictionary
            duration: Processing duration in seconds
        """
        
        admin_telegram_id = os.getenv('ADMIN_TELEGRAM_ID')
        if not admin_telegram_id:
            return
        
        message = f"""
        📊 Weekly AISRI Update Report
        
        ✅ Successfully updated: {results['success']}
        ⏭️  Skipped: {results['skipped']}
        ❌ Failed: {results['failed']}
        ⏱️  Duration: {duration:.1f}s
        
        🕐 Completed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
        """
        
        if results['errors']:
            message += f"\n\n❌ Errors:\n"
            for error in results['errors'][:5]:  # Show first 5 errors
                message += f"- {error['user_id']}: {error['error']}\n"
        
        try:
            await self.comm.send_telegram_message(
                chat_id=admin_telegram_id,
                text=message
            )
        except Exception as e:
            logger.error(f"Failed to send admin notification: {e}")


# ═══════════════════════════════════════════════════════════════════════
# Script Entry Point
# ═══════════════════════════════════════════════════════════════════════

async def main():
    """Run the weekly AISRI update"""
    updater = AISRIScheduledUpdater()
    results = await updater.run_weekly_update()
    
    # Exit with error code if there were failures
    if results['failed'] > 0:
        sys.exit(1)
    
    sys.exit(0)


if __name__ == "__main__":
    asyncio.run(main())
