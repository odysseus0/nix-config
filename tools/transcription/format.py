"""Render existing JSON with speaker-aware writers; no inference or model downloads."""
import argparse
from dataclasses import fields
import json
from pathlib import Path

from mlx_qwen3_asr.transcribe import TranscriptionResult
from mlx_qwen3_asr.writers import get_writer

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("json_file", type=Path)
parser.add_argument("--output-dir", type=Path)
args = parser.parse_args()
data = json.loads(args.json_file.read_text())
keys = {f.name for f in fields(TranscriptionResult)}
result = TranscriptionResult(**{k: v for k, v in data.items() if k in keys})
if not result.speaker_segments:
    parser.error("JSON has no speaker segments; reformatting cannot infer speakers.")
output = args.output_dir or args.json_file.parent
output.mkdir(parents=True, exist_ok=True)
for fmt in ("txt", "srt", "vtt", "tsv"):
    path = output / (args.json_file.stem + ".speakers." + fmt)
    get_writer(fmt)(result, str(path))
    print(path)
