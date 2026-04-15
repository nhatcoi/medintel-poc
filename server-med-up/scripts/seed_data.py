"""Reference data seeding (standalone script)."""

from core.database import SessionLocal
from models.profile import Profile


def seed():
    db = SessionLocal()
    try:
        from sqlalchemy import select
        if not db.scalars(select(Profile).limit(1)).first():
            db.add(Profile(full_name="Demo User", role="patient"))
            db.commit()
            print("Seeded demo profile")
        else:
            print("Data already exists")
    finally:
        db.close()


if __name__ == "__main__":
    seed()
