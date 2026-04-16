from sqlalchemy import create_engine, select, text
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
import uuid

# Configuration
DB_URL = "postgresql://medintel:medintel@103.252.136.113:5435/medintel_orm"

def setup_test_scenario():
    engine = create_engine(DB_URL)
    with Session(engine) as db:
        # 1. Find a valid patient-caregiver link where consent is granted
        # and there are actual schedules to test with.
        sql = text("""
            SELECT s.schedule_id, r.profile_id, cgm.profile_id as caregiver_id
            FROM medication_schedules s
            JOIN medications m ON s.medication_id = m.medication_id
            JOIN treatment_periods tp ON m.period_id = tp.period_id
            JOIN medical_records r ON tp.record_id = r.record_id
            JOIN care_group_patients cgp ON r.profile_id = cgp.patient_id
            JOIN care_group_members cgm ON cgp.group_id = cgm.group_id
            WHERE cgp.consent_status = 'granted'
            AND cgm.profile_id != r.profile_id
            LIMIT 1
        """)
        result = db.execute(sql).first()
        
        if not result:
            # Fallback: Find any schedule and a profile to act as caregiver
            query_standalone = text("""
                SELECT s.schedule_id, r.profile_id 
                FROM medication_schedules s
                JOIN medications m ON s.medication_id = m.medication_id
                JOIN treatment_periods tp ON m.period_id = tp.period_id
                JOIN medical_records r ON tp.record_id = r.record_id
                LIMIT 1
            """)
            result_standalone = db.execute(query_standalone).first()
            if not result_standalone:
                print("Error: No medications or schedules found in database.")
                return
                
            schedule_id, patient_id = result_standalone
            
            # Find any other profile to be caregiver
            any_caregiver = db.execute(text("SELECT profile_id FROM profiles WHERE profile_id != :p_id LIMIT 1"), {"p_id": patient_id}).scalar()
            if not any_caregiver:
                print("Error: Need at least 2 profiles to test caregiver notifications.")
                return
            
            # Force link them into a new group
            group_id = uuid.uuid4()
            db.execute(text("INSERT INTO care_groups (group_id, group_name, created_by_profile_id, created_at, updated_at) VALUES (:g_id, 'Test Group', :cg_id, now(), now())"), {"g_id": group_id, "cg_id": any_caregiver})
            db.execute(text("INSERT INTO care_group_patients (id, group_id, patient_id, added_by_profile_id, added_at, consent_status) VALUES (:id, :g_id, :p_id, :cg_id, now(), 'granted')"), {"id": uuid.uuid4(), "g_id": group_id, "p_id": patient_id, "cg_id": any_caregiver})
            db.execute(text("INSERT INTO care_group_members (member_id, group_id, profile_id, role, joined_at) VALUES (:m_id, :g_id, :cg_id, 'caregiver', now())"), {"m_id": uuid.uuid4(), "g_id": group_id, "cg_id": any_caregiver})
            
            caregiver = any_caregiver
            print(f"Force-linked: Patient {patient_id} <-> Caregiver {caregiver} for testing.")
        else:
            schedule_id, patient_id, caregiver = result
            print(f"Success: Found existing caregiver {caregiver} for patient {patient_id}")

        # 3. Insert a 'pending' log in the past (1 hour ago)
        log_id = uuid.uuid4()
        past_time = datetime.now(timezone.utc) - timedelta(hours=1)
        
        insert_log = text("""
            INSERT INTO medication_logs (log_id, schedule_id, profile_id, scheduled_datetime, status, created_at, updated_at)
            VALUES (:l_id, :s_id, :p_id, :s_dt, 'pending', now(), now())
        """)
        
        db.execute(insert_log, {
            "l_id": log_id,
            "s_id": schedule_id,
            "p_id": patient_id,
            "s_dt": past_time
        })
        
        db.commit()
        print(f"\n[TEST DATA CREATED]")
        print(f"Log ID: {log_id}")
        print(f"Patient: {patient_id}")
        print(f"Scheduled At: {past_time}")
        print(f"Status: pending")
        print("\nNow call the trigger API again via POST /api/v1/reminders/trigger-checks")

if __name__ == "__main__":
    setup_test_scenario()
