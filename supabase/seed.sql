-- ============================================
-- SafeStride Power Cells Seed Data
-- ============================================

BEGIN;

DELETE FROM public.user_power_cells;
DELETE FROM public.power_cell_types;
DELETE FROM public.power_cell_protocols;

INSERT INTO public.power_cell_protocols (
  protocol_name,
  display_name,
  description,
  color_hex,
  icon_class,
  training_focus
)
VALUES
  ('START', 'START Protocol', 'Foundation and movement preparation', '#10B981', 'fa-play-circle', 'Readiness and movement quality'),
  ('ENGINE', 'ENGINE Protocol', 'Aerobic base and endurance development', '#3B82F6', 'fa-tachometer-alt', 'Aerobic engine and durability'),
  ('OXYGEN', 'OXYGEN Protocol', 'VO2 and aerobic capacity development', '#8B5CF6', 'fa-wind', 'Oxygen uptake and threshold support'),
  ('POWER', 'POWER Protocol', 'Speed and anaerobic power sessions', '#EF4444', 'fa-bolt', 'Neuromuscular speed and acceleration'),
  ('ZONES', 'ZONES Protocol', 'Zone-guided adaptation sessions', '#F59E0B', 'fa-layer-group', 'Heart rate and effort control'),
  ('STRENGTH', 'STRENGTH Protocol', 'Strength and resilience sessions', '#EC4899', 'fa-dumbbell', 'Structural integrity and injury prevention'),
  ('LONG_RUN', 'LONG RUN Protocol', 'Progressive long run endurance', '#6366F1', 'fa-route', 'Endurance and race-specific stamina')
ON CONFLICT (protocol_name) DO UPDATE
SET
  display_name = EXCLUDED.display_name,
  description = EXCLUDED.description,
  color_hex = EXCLUDED.color_hex,
  icon_class = EXCLUDED.icon_class,
  training_focus = EXCLUDED.training_focus;

WITH p AS (
  SELECT id, protocol_name FROM public.power_cell_protocols
)
INSERT INTO public.power_cell_types (
  name,
  protocol_id,
  zone_requirement,
  aisri_minimum,
  duration_minutes,
  intensity,
  description
)
VALUES
  ('START-Foundation-10', (SELECT id FROM p WHERE protocol_name = 'START'), 1, 20, 10, 'easy', 'Light warm-up and mobility activation'),
  ('START-Dynamic-15', (SELECT id FROM p WHERE protocol_name = 'START'), 1, 30, 15, 'easy', 'Dynamic drill sequence and movement prep'),
  ('START-Complete-20', (SELECT id FROM p WHERE protocol_name = 'START'), 1, 40, 20, 'moderate', 'Complete warm-up with coordination drills'),

  ('ENGINE-Easy-30', (SELECT id FROM p WHERE protocol_name = 'ENGINE'), 1, 30, 30, 'easy', 'Easy aerobic base run'),
  ('ENGINE-Steady-45', (SELECT id FROM p WHERE protocol_name = 'ENGINE'), 2, 45, 45, 'moderate', 'Steady aerobic conditioning run'),
  ('ENGINE-Tempo-60', (SELECT id FROM p WHERE protocol_name = 'ENGINE'), 3, 60, 60, 'hard', 'Tempo effort with sustained control'),
  ('ENGINE-Long-90', (SELECT id FROM p WHERE protocol_name = 'ENGINE'), 3, 65, 90, 'moderate', 'Extended endurance progression'),

  ('OXYGEN-Intervals-30', (SELECT id FROM p WHERE protocol_name = 'OXYGEN'), 4, 65, 30, 'hard', 'VO2 intervals with controlled recovery'),
  ('OXYGEN-Threshold-40', (SELECT id FROM p WHERE protocol_name = 'OXYGEN'), 4, 70, 40, 'hard', 'Threshold block session'),
  ('OXYGEN-Peak-25', (SELECT id FROM p WHERE protocol_name = 'OXYGEN'), 5, 75, 25, 'very_hard', 'Peak oxygen power intervals'),

  ('POWER-Intervals-30', (SELECT id FROM p WHERE protocol_name = 'POWER'), 4, 70, 30, 'very_hard', 'High-intensity power intervals'),
  ('POWER-Hills-20', (SELECT id FROM p WHERE protocol_name = 'POWER'), 4, 65, 20, 'very_hard', 'Short uphill sprint repeats'),
  ('POWER-Fartlek-35', (SELECT id FROM p WHERE protocol_name = 'POWER'), 4, 70, 35, 'hard', 'Variable speed power development'),
  ('POWER-Track-40', (SELECT id FROM p WHERE protocol_name = 'POWER'), 5, 75, 40, 'very_hard', 'Track speed and stride power'),

  ('ZONES-Progressive-45', (SELECT id FROM p WHERE protocol_name = 'ZONES'), 2, 50, 45, 'moderate', 'Progressive multi-zone conditioning'),
  ('ZONES-Pyramid-50', (SELECT id FROM p WHERE protocol_name = 'ZONES'), 3, 60, 50, 'hard', 'Pyramid heart-rate zone ladder'),
  ('ZONES-Mixed-40', (SELECT id FROM p WHERE protocol_name = 'ZONES'), 3, 55, 40, 'moderate', 'Alternating mixed-zone blocks'),

  ('STRENGTH-Foundation-30', (SELECT id FROM p WHERE protocol_name = 'STRENGTH'), 1, 35, 30, 'moderate', 'Core and stability base session'),
  ('STRENGTH-Runners-40', (SELECT id FROM p WHERE protocol_name = 'STRENGTH'), 1, 40, 40, 'moderate', 'Runner-focused lower body strength'),
  ('STRENGTH-Power-45', (SELECT id FROM p WHERE protocol_name = 'STRENGTH'), 2, 50, 45, 'hard', 'Explosive strength and plyometric mix'),
  ('STRENGTH-Maintenance-25', (SELECT id FROM p WHERE protocol_name = 'STRENGTH'), 1, 30, 25, 'easy', 'Short maintenance and prehab set'),

  ('LONG_RUN-Base-60', (SELECT id FROM p WHERE protocol_name = 'LONG_RUN'), 2, 50, 60, 'easy', 'Base long run at easy effort'),
  ('LONG_RUN-Steady-75', (SELECT id FROM p WHERE protocol_name = 'LONG_RUN'), 2, 55, 75, 'moderate', 'Steady state long endurance run'),
  ('LONG_RUN-Progressive-90', (SELECT id FROM p WHERE protocol_name = 'LONG_RUN'), 3, 60, 90, 'moderate', 'Progressive pace long run'),
  ('LONG_RUN-Endurance-120', (SELECT id FROM p WHERE protocol_name = 'LONG_RUN'), 3, 65, 120, 'moderate', 'Extended aerobic endurance run'),
  ('LONG_RUN-Marathon-150', (SELECT id FROM p WHERE protocol_name = 'LONG_RUN'), 3, 70, 150, 'hard', 'Marathon-specific long run')
ON CONFLICT (name) DO UPDATE
SET
  protocol_id = EXCLUDED.protocol_id,
  zone_requirement = EXCLUDED.zone_requirement,
  aisri_minimum = EXCLUDED.aisri_minimum,
  duration_minutes = EXCLUDED.duration_minutes,
  intensity = EXCLUDED.intensity,
  description = EXCLUDED.description;

COMMIT;

SELECT COUNT(*) AS protocol_count FROM public.power_cell_protocols;
SELECT protocol_name, COUNT(*) AS cell_count
FROM public.power_cell_types pct
JOIN public.power_cell_protocols pcp ON pcp.id = pct.protocol_id
GROUP BY protocol_name
ORDER BY protocol_name;
SELECT COUNT(*) AS total_cell_count FROM public.power_cell_types;
