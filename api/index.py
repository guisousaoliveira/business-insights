"""Entrypoint para deployment serverless no Vercel."""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from app.main import app
