"""Synthesize the original AURA demo beds; no recordings or third-party samples."""
from pathlib import Path
import array
import math
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1]
for name, notes in [
    ("orbita", [130.81, 164.81, 196.0, 246.94]),
    ("afterglow", [110.0, 146.83, 174.61, 220.0]),
]:
    data = array.array("h")
    for i in range(RATE * 40):
        t = i / RATE
        fade = min(t / 2, 1, (40 - t) / 3)
        chord = sum(
            math.sin(2 * math.pi * f * t + 0.025 * math.sin(t * 0.5))
            * 0.038 * (1 + 0.18 * math.sin(t * 0.7 + j))
            for j, f in enumerate(notes)
        )
        step = int(t / 0.625) % 8
        f = notes[[0, 2, 1, 3, 2, 1, 3, 2][step]] * 4
        env = math.exp(-6 * (t % 0.625))
        pluck = (math.sin(2 * math.pi * f * t) + 0.25 * math.sin(2 * math.pi * f * 2 * t)) * 0.055 * env
        data.append(int(30000 * fade * (chord + pluck)))
    with wave.open(str(ROOT / "assets" / "audio" / f"{name}.wav"), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(data.tobytes())
