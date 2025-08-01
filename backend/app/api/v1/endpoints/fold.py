from fastapi import APIRouter, HTTPException
from app.schemas.fold import FoldRequest, FoldResponse
from app.core.config import settings
from app.services.nuss3d import run_nuss3d

router = APIRouter()

@router.post("", response_model=FoldResponse)
def fold(req: FoldRequest):
    seq = req.sequence.replace("\n", "").replace("\r","").upper()
    if len(seq) > settings.MAX_N:
        raise HTTPException(status_code=400, detail=f"Secuencia demasiado larga (>{settings.MAX_N}) para demo.")
    if req.method not in settings.ALLOWED_METHODS:
        raise HTTPException(status_code=400, detail="Método no permitido.")
    result = run_nuss3d(seq, req.method, req.threads)
    return FoldResponse(job_id=result["job_id"], method=req.method, threads=req.threads,
                        files=result["files"], meta=result["meta"])
