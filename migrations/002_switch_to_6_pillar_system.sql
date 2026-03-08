-- Migration: 002_switch_to_6_pillar_system.sql (SQLite version)
-- Switch from 5-pillar to 6-pillar AISRI System

-- Add new 6-pillar columns to physical_assessments
ALTER TABLE physical_assessments ADD COLUMN pillar_mobility_flexibility INTEGER DEFAULT 0;
ALTER TABLE physical_assessments ADD COLUMN pillar_core_strength INTEGER DEFAULT 0;
ALTER TABLE physical_assessments ADD COLUMN pillar_mental_resilience INTEGER DEFAULT 0;
ALTER TABLE physical_assessments ADD COLUMN pillar_recovery INTEGER DEFAULT 0;
ALTER TABLE physical_assessments ADD COLUMN pillar_injury_prevention INTEGER DEFAULT 0;
ALTER TABLE physical_assessments ADD COLUMN pillar_performance INTEGER DEFAULT 0;
ALTER TABLE physical_assessments ADD COLUMN aisri_score_v2 INTEGER DEFAULT 0;
ALTER TABLE physical_assessments ADD COLUMN assessed_by TEXT DEFAULT 'System';
