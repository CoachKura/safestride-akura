-- Check if Strava columns exist in profiles table
SELECT 
    column_name, 
    data_type 
FROM 
    information_schema.columns 
WHERE 
    table_name = 'profiles' 
    AND column_name LIKE '%strava%'
ORDER BY 
    column_name;
