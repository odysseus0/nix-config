"""Use the user's local Hugging Face login without putting credentials in Nix."""
import os
from pathlib import Path
import sys

from huggingface_hub import get_token

if not any(os.environ.get(key) for key in ("PYANNOTE_AUTH_TOKEN", "HF_TOKEN", "HUGGINGFACE_TOKEN")):
    token = get_token()
    if token:
        os.environ["PYANNOTE_AUTH_TOKEN"] = token

cli = str(Path(sys.executable).parent / "mlx-qwen3-asr")
os.execv(cli, [cli, *sys.argv[1:]])
