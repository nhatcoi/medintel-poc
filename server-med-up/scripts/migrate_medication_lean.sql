BEGIN;

-- Lean Medication model:
-- keep only core fields used by cabinet/schedule/log flows.
ALTER TABLE medications
    DROP COLUMN IF EXISTS active_ingredient,
    DROP COLUMN IF EXISTS strength,
    DROP COLUMN IF EXISTS dosage_form,
    DROP COLUMN IF EXISTS route,
    DROP COLUMN IF EXISTS duration_days,
    DROP COLUMN IF EXISTS side_effects,
    DROP COLUMN IF EXISTS contraindications,
    DROP COLUMN IF EXISTS interactions,
    DROP COLUMN IF EXISTS storage_instructions,
    DROP COLUMN IF EXISTS prescribing_doctor,
    DROP COLUMN IF EXISTS prescription_number,
    DROP COLUMN IF EXISTS prescription_date,
    DROP COLUMN IF EXISTS total_quantity;

-- Lean MedicationSchedule model:
-- keep only scheduled_time + status.
ALTER TABLE medication_schedules
    DROP COLUMN IF EXISTS repeat_pattern,
    DROP COLUMN IF EXISTS repeat_days,
    DROP COLUMN IF EXISTS start_date,
    DROP COLUMN IF EXISTS end_date,
    DROP COLUMN IF EXISTS reminder_enabled,
    DROP COLUMN IF EXISTS reminder_time_before,
    DROP COLUMN IF EXISTS reminder_sound;

-- Normalize defaults in lean mode.
ALTER TABLE medications
    ALTER COLUMN status SET DEFAULT 'active';

ALTER TABLE medication_schedules
    ALTER COLUMN status SET DEFAULT 'active';

UPDATE medications
SET status = 'active'
WHERE status IS NULL OR btrim(status) = '';

UPDATE medication_schedules
SET status = 'active'
WHERE status IS NULL OR btrim(status) = '';

COMMIT;
