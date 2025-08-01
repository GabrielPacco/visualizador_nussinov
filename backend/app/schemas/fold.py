from pydantic import BaseModel, Field
from typing import Literal

Method = Literal["oryg", "tstile", "tilecorr", "pluto", "3D"]

class FoldRequest(BaseModel):
    sequence: str = Field(..., min_length=10)
    method: Method
    threads: int = Field(ge=1, le=64)

class FoldResponse(BaseModel):
    job_id: str
    method: Method
    threads: int
    files: dict
    meta: dict
