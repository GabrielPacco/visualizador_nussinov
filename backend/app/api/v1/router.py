from fastapi import APIRouter
from app.api.v1.endpoints.health import router as health_router
from app.api.v1.endpoints.fold import router as fold_router
from app.api.v1.endpoints.result import router as result_router  # <-- import absoluto, evita ambigüedades

api_router = APIRouter()
api_router.include_router(health_router, prefix="", tags=["health"])
api_router.include_router(fold_router,    prefix="/fold", tags=["fold"])
api_router.include_router(result_router,  prefix="", tags=["result"])
