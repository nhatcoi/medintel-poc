"""Reference data seeding (standalone script)."""

from core.database import SessionLocal
from models.medical import DiseaseCategory


def seed():
    db = SessionLocal()
    try:
        from sqlalchemy import select
        if not db.scalars(select(DiseaseCategory).limit(1)).first():
            db.add(DiseaseCategory(category_name="Chua phan loai"))
            db.commit()
            print("Seeded default disease category")
        else:
            print("Data already exists")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
