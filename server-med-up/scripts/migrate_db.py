from sqlalchemy import text
import sys
import os

# Add parent dir to path to import core/models
sys.path.append(os.getcwd())

from core.config import settings
from core.database import engine

def migrate():
    print(f"Connecting to {settings.database_url}...")
    
    # Tables and their columns to check
    schema_updates = {
        "medications": [
            ("active_ingredient", "TEXT"),
            ("strength", "VARCHAR(100)"),
            ("dosage_form", "VARCHAR(100)"),
            ("dosage", "VARCHAR(100)"),
            ("frequency", "VARCHAR(100)"),
            ("route", "VARCHAR(100)"),
            ("duration_days", "INTEGER"),
            ("end_date", "DATE"),
            ("instructions", "TEXT"),
            ("side_effects", "TEXT"),
            ("contraindications", "TEXT"),
            ("interactions", "TEXT"),
            ("storage_instructions", "TEXT"),
            ("prescribing_doctor", "VARCHAR(255)"),
            ("prescription_number", "VARCHAR(100)"),
            ("prescription_date", "DATE"),
            ("total_quantity", "NUMERIC(10, 2)"),
            ("quantity_unit", "VARCHAR(50)"),
            ("remaining_quantity", "NUMERIC(10, 2)"),
            ("notes", "TEXT"),
            ("status", "VARCHAR(64)"),
        ],
        "medication_schedules": [
            ("repeat_pattern", "VARCHAR(50)"),
            ("repeat_days", "VARCHAR(50)"),
            ("start_date", "DATE"),
            ("end_date", "DATE"),
            ("reminder_enabled", "BOOLEAN DEFAULT TRUE"),
            ("reminder_time_before", "INTEGER"),
            ("reminder_sound", "VARCHAR(100)"),
            ("status", "VARCHAR(64)"),
        ]
    }

    with engine.connect() as conn:
        for table_name, columns in schema_updates.items():
            print(f"\n--- Migrating table: {table_name} ---")
            for col_name, col_type in columns:
                try:
                    print(f"Checking column: {col_name}...")
                    conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {col_name} {col_type};"))
                    conn.commit()
                    print(f"  Successfully added {col_name}")
                except Exception as e:
                    if "already exists" in str(e).lower():
                        print(f"  Column {col_name} already exists. Skipping.")
                    else:
                        print(f"  Error adding {col_name} to {table_name}: {e}")
                    conn.rollback()

    print("\nMigration complete! You can now restart your uvicorn server.")

if __name__ == "__main__":
    migrate()
