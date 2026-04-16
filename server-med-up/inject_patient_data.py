from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
import uuid
import sys

# Configuration
DB_URL = "postgresql://medintel:medintel@103.252.136.113:5435/medintel_orm"
CAREGIVER_ID = "6c44702e-c0c5-4cac-bd06-f545f2d8412b"

def setup_patient_data(patient_id):
    engine = create_engine(DB_URL)
    with Session(engine) as db:
        print(f"--- Setting up data for Patient: {patient_id} ---")
        
        # 1. Medical Record
        record_id = db.execute(text("SELECT record_id FROM medical_records WHERE profile_id = :p_id LIMIT 1"), {"p_id": patient_id}).scalar()
        if not record_id:
            record_id = uuid.uuid4()
            db.execute(text("""
                INSERT INTO medical_records (record_id, profile_id, disease_name, treatment_start_date, created_at, updated_at)
                VALUES (:r_id, :p_id, 'Tiểu đường Type 2', CURRENT_DATE, now(), now())
            """), {"r_id": record_id, "p_id": patient_id})
            print(f"Created medical record.")
        
        # 2. Treatment Period
        period_id = db.execute(text("SELECT period_id FROM treatment_periods WHERE record_id = :r_id LIMIT 1"), {"r_id": record_id}).scalar()
        if not period_id:
            period_id = uuid.uuid4()
            db.execute(text("""
                INSERT INTO treatment_periods (period_id, record_id, period_name, start_date, created_at, updated_at)
                VALUES (:pe_id, :r_id, 'Phác đồ Insulin', CURRENT_DATE, now(), now())
            """), {"pe_id": period_id, "r_id": record_id})
            print(f"Created treatment period.")

        # 3. Medication
        med_id = db.execute(text("SELECT medication_id FROM medications WHERE period_id = :pe_id LIMIT 1"), {"pe_id": period_id}).scalar()
        if not med_id:
            med_id = uuid.uuid4()
            db.execute(text("""
                INSERT INTO medications (medication_id, period_id, medication_name, dosage, frequency, start_date, created_at, updated_at)
                VALUES (:m_id, :pe_id, 'Metformin', '500mg', '2 lần/ngày', CURRENT_DATE, now(), now())
            """), {"m_id": med_id, "pe_id": period_id})
            print(f"Created medication.")

        # 4. Schedule
        sched_id = db.execute(text("SELECT schedule_id FROM medication_schedules WHERE medication_id = :m_id LIMIT 1"), {"m_id": med_id}).scalar()
        if not sched_id:
            sched_id = uuid.uuid4()
            db.execute(text("""
                INSERT INTO medication_schedules (schedule_id, medication_id, scheduled_time, created_at, updated_at)
                VALUES (:s_id, :m_id, '18:00:00', now(), now())
            """), {"s_id": sched_id, "m_id": med_id})
            print(f"Created schedule.")

        # 5. Missed Log (30 mins ago)
        log_id = uuid.uuid4()
        past_time = datetime.now(timezone.utc) - timedelta(minutes=30)
        db.execute(text("""
            INSERT INTO medication_logs (log_id, schedule_id, profile_id, scheduled_datetime, status, created_at, updated_at)
            VALUES (:l_id, :s_id, :p_id, :s_dt, 'pending', now(), now())
        """), {
            "l_id": log_id,
            "s_id": sched_id,
            "p_id": patient_id,
            "s_dt": past_time
        })
        print(f"Created missed log at {past_time}")

        # 6. Ensure Care Group linkage exists
        # Assuming user already added them, but we verify granting just in case for reminders
        db.execute(text("""
            UPDATE care_group_patients SET consent_status = 'granted' 
            WHERE patient_id = :p_id AND added_by_profile_id = :cg_id
        """), {"p_id": patient_id, "cg_id": CAREGIVER_ID})

        db.commit()
        print("\n[OK] Mock data successfully generated.")

if __name__ == "__main__":
    p_id = sys.argv[1] if len(sys.argv) > 1 else "58520d0f-4ea7-4697-9583-986ede870696"
    setup_patient_data(p_id)
