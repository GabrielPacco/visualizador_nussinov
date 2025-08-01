from fastapi import APIRouter, HTTPException
from app.core.config import settings
import json
from pathlib import Path

router = APIRouter()

@router.get("/result/{job_id}")
def get_result(job_id: str):
    job_dir = settings.JOBS_DIR / job_id
    s_json = job_dir / "S.json"
    if not s_json.exists():
        raise HTTPException(status_code=404, detail="S.json no encontrado")
    return json.loads(s_json.read_text())
