from pathlib import Path
from typing import ClassVar, Tuple, List
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Rutas
    PROJECT_ROOT: Path = Path(__file__).resolve().parents[2]
    BIN_DIR: Path = PROJECT_ROOT / "nuss3d" / "build"
    NUSS_BIN: Path = BIN_DIR / "nuss3d"

    RUNTIME_DIR: Path = PROJECT_ROOT / "app" / "runtime"
    JOBS_DIR: Path = RUNTIME_DIR / "jobs"
    CACHE_DIR: Path = RUNTIME_DIR / "cache"

    # Límites / CORS
    MAX_N: int = 6000
    CORS_ORIGINS: List[str] = ["http://localhost:5173"]

    # Constante de clase (no es campo del modelo)
    ALLOWED_METHODS: ClassVar[Tuple[str, ...]] = ("oryg", "tstile", "tilecorr", "pluto", "3D")

settings = Settings()
