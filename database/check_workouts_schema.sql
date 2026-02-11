-- Diagnostic Query: Check actual workouts table structure
-- Run this in Supabase SQL Editor to see what columns exist

SELECT 
    column_name,
    data_type,
    is_nullable
FROM 
    information_schema.columns
WHERE 
    table_schema = 'public' 
    AND table_name = 'workouts'
ORDER BY 
    ordinal_position;
