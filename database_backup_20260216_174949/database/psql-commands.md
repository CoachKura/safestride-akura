# 🗄️ Quick Database Commands Reference

Once connected via `.\connect-db.ps1`, use these commands:

## 📋 List Tables
```sql
\dt
```

## 🔍 Describe Table Structure
```sql
\d garmin_devices
\d garmin_connections
\d garmin_activities
\d garmin_pushed_workouts
```

## 📊 Query Tables
```sql
-- Check if Garmin tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE 'garmin%';

-- Count rows in each table
SELECT 
    (SELECT COUNT(*) FROM garmin_devices) as devices,
    (SELECT COUNT(*) FROM garmin_connections) as connections,
    (SELECT COUNT(*) FROM garmin_activities) as activities,
    (SELECT COUNT(*) FROM garmin_pushed_workouts) as workouts;

-- View table columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'garmin_devices'
ORDER BY ordinal_position;
```

## 🔧 Common psql Commands
```
\l          - List databases
\dt         - List tables
\d table    - Describe table
\du         - List users
\q          - Quit
\?          - Help
\h SQL_CMD  - Help on SQL command
```

## 📝 Run SQL Files
```sql
-- From inside psql
\i /path/to/file.sql

-- Or from command line
docker run -it --rm -v ${PWD}:/workspace postgres:16-alpine \
    psql -h HOST -U USER -d DB -f /workspace/file.sql
```

## 🎯 Quick Tests
```sql
-- Insert test device
INSERT INTO garmin_devices (user_id, device_id, device_name) 
VALUES (
    (SELECT id FROM auth.users LIMIT 1),
    'test-device-123',
    'Test Forerunner 955'
);

-- View test device
SELECT * FROM garmin_devices;

-- Delete test device
DELETE FROM garmin_devices WHERE device_id = 'test-device-123';
```

## 🚪 Exit
```
\q
```
or press `Ctrl+D`
