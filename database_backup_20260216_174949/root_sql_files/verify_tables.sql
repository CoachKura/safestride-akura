SELECT 
    table_name,
    'Exists ' as status
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN (
    'profiles',
    'athlete_goals',
    'structured_workouts',
    'strava_connections',
    'strava_activities',
    'garmin_connections',
    'garmin_activities'
)
ORDER BY table_name;
