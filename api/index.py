import sys
from pathlib import Path

# Add backend directory to sys.path so app modules are resolvable.
# Vercel menginstal root requirements.txt lalu menjalankan file ini sebagai
# serverless function, jadi import harus tahan terhadap dua layout:
# 1. backend/ sebagai package (sys.path = BACKEND_DIR) -> "from app.main import app"
# 2. repo root sebagai package -> "from backend.app.main import app"
ROOT_DIR = Path(__file__).resolve().parent.parent
BACKEND_DIR = ROOT_DIR / "backend"
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

try:
    from app.main import app
except ModuleNotFoundError:
    from backend.app.main import app

# Expose app for Vercel serverless function
handler = app
