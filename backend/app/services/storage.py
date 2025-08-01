from pathlib import Path
import hashlib

def write_text(path: Path, text: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text)

def calc_hash(s: str) -> str:
    return hashlib.sha256(s.encode()).hexdigest()
