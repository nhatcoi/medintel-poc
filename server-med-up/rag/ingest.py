"""CLI ingestion: python -m rag.ingest <json_file>

Reads a JSON array of drug objects, chunks them, embeds, and stores in DB.
"""

from __future__ import annotations

import json
import sys
import uuid

from sqlalchemy.orm import Session

from core.database import SessionLocal
from models.rag import TbdfDrug, TbdfDrugChunk
from rag.chunker import chunk_drug
from rag.embedding import embed_sync


def ingest_file(path: str) -> None:
    with open(path, encoding="utf-8") as f:
        drugs = json.load(f)

    if not isinstance(drugs, list):
        drugs = [drugs]

    db: Session = SessionLocal()
    total_chunks = 0

    try:
        for drug_data in drugs:
            name = drug_data.get("name_display", drug_data.get("name", "Unknown"))
            ext_id = drug_data.get("id", drug_data.get("external_id", 0))

            drug = TbdfDrug(
                drug_id=uuid.uuid4(),
                external_id=int(ext_id),
                canonical_url=drug_data.get("url", ""),
                name_display=name,
                registration_no=drug_data.get("registration_no"),
                dosage_form=drug_data.get("dosage_form"),
                ingredient_short=drug_data.get("ingredient_short"),
                raw_document=drug_data,
            )
            db.add(drug)
            db.flush()

            chunks = chunk_drug(drug_data, drug_name=name)
            if not chunks:
                continue

            texts = [c.content for c in chunks]
            embeddings = embed_sync(texts)

            for chunk, emb in zip(chunks, embeddings):
                db_chunk = TbdfDrugChunk(
                    chunk_id=uuid.uuid4(),
                    drug_id=drug.drug_id,
                    chunk_ordinal=chunk.ordinal,
                    section=chunk.section,
                    content=chunk.content,
                    embedding=emb,
                )
                db.add(db_chunk)
                total_chunks += 1

        db.commit()
        print(f"Ingested {len(drugs)} drugs, {total_chunks} chunks")
    except Exception:
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python -m rag.ingest <json_file>")
        sys.exit(1)
    ingest_file(sys.argv[1])
