#!/usr/bin/env python3
"""Build Pecking Order's deterministic authored music stems.

The shipped Ogg files are deliberately reproducible: no network service, sample
library, or nondeterministic synthesizer is involved.  Source WAVs live only in
a temporary directory and are removed after ffmpeg encodes the compact Web
assets.
"""

from __future__ import annotations

import argparse
import math
import random
import shutil
import struct
import subprocess
import tempfile
import wave
from pathlib import Path


SAMPLE_RATE = 16_000
TAU = math.tau


def _soft_clip(value: float) -> float:
    return math.tanh(value * 1.35) / math.tanh(1.35)


def _note(midi: int) -> float:
    return 440.0 * (2.0 ** ((midi - 69) / 12.0))


def _osc(freq: float, time: float, shape: str = "sine") -> float:
    phase = (time * freq) % 1.0
    if shape == "triangle":
        return 1.0 - 4.0 * abs(phase - 0.5)
    if shape == "soft_square":
        return math.tanh(math.sin(TAU * phase) * 2.2) * 0.72
    return math.sin(TAU * phase)


def _pulse(time: float, rate: float, decay: float = 7.0) -> float:
    return math.exp(-((time * rate) % 1.0) * decay)


def _chord(time: float, notes: tuple[int, ...], warmth: float = 1.0) -> float:
    total = 0.0
    for index, midi in enumerate(notes):
        freq = _note(midi)
        weight = (0.38, 0.28, 0.21, 0.13)[min(index, 3)]
        total += _osc(freq, time) * weight
        total += _osc(freq * 2.0, time) * weight * 0.08 * warmth
    return total


def _base(time: float, _rng: random.Random) -> float:
    progression = (
        (48, 52, 55, 59), (45, 48, 52, 55), (41, 45, 48, 52), (43, 47, 50, 55),
        (48, 52, 55, 59), (50, 53, 57, 60), (45, 48, 52, 57), (43, 47, 50, 55),
    )
    chord_index = int(time / 3.0) % len(progression)
    local = time % 3.0
    fade = min(1.0, local / 0.18, (3.0 - local) / 0.22)
    harmony = _chord(time, progression[chord_index]) * (0.76 + 0.08 * math.sin(TAU * time / 24.0))
    melody = (72, 76, 79, 76, 69, 72, 76, 79, 65, 69, 72, 76, 67, 71, 74, 79)
    step = int(time * 2.0) % len(melody)
    mallet = (_osc(_note(melody[step]), time) + 0.22 * _osc(_note(melody[step]) * 2.0, time))
    mallet *= _pulse(time, 2.0, 6.2)
    return (harmony * 0.18 * fade) + (mallet * 0.045)


def _pressure(time: float, rng: random.Random) -> float:
    tick = _pulse(time, 4.0, 24.0)
    printer = _pulse(time + 0.125, 2.0, 16.0)
    motor = _osc(61.0, time, "soft_square") * 0.07 + _osc(92.0, time) * 0.04
    paper = (rng.random() * 2.0 - 1.0) * printer * 0.045
    alarm = _osc(740.0 + 18.0 * math.sin(TAU * time / 3.0), time) * tick * 0.06
    return motor + paper + alarm


def _momentum(time: float, _rng: random.Random) -> float:
    melody = (60, 64, 67, 72, 57, 64, 67, 71, 53, 60, 65, 69, 55, 62, 67, 72)
    step = int(time * 2.0) % len(melody)
    envelope = _pulse(time, 2.0, 5.3)
    bell = _osc(_note(melody[step]), time) * 0.11
    bell += _osc(_note(melody[step]) * 2.01, time) * 0.035
    lift = max(0.0, math.sin(TAU * time / 12.0)) * _osc(_note(48), time) * 0.025
    return bell * envelope + lift


def _review(time: float, _rng: random.Random) -> float:
    progression = ((45, 48, 52, 57), (41, 45, 48, 52), (43, 47, 50, 55), (48, 52, 55, 60))
    chord_index = int(time / 4.0) % len(progression)
    pad = _chord(time, progression[chord_index], 0.35) * 0.13
    stamp = _osc(110.0, time, "triangle") * _pulse(time + 0.25, 0.5, 18.0) * 0.035
    top_note = (69, 65, 67, 72)[chord_index]
    resolve = _osc(_note(top_note), time) * _pulse(time, 0.5, 5.5) * 0.038
    return pad + stamp + resolve


def _ambient(time: float, rng: random.Random) -> float:
    hvac = _osc(60.0, time) * 0.020 + _osc(120.0, time) * 0.008
    air = (rng.random() * 2.0 - 1.0) * (0.012 + 0.004 * math.sin(TAU * time / 8.0))
    keyboard = (rng.random() * 2.0 - 1.0) * _pulse(time + 0.19, 1.5, 28.0) * 0.018
    distant_cluck = _osc(510.0 + 90.0 * math.sin(TAU * time * 0.7), time)
    distant_cluck *= _pulse(time + 0.43, 0.25, 36.0) * 0.012
    return hvac + air + keyboard + distant_cluck


def _harvest(time: float, rng: random.Random) -> float:
    kick = _osc(78.0, time, "triangle") * _pulse(time, 2.0, 13.0) * 0.12
    grain = (rng.random() * 2.0 - 1.0) * _pulse(time + 0.125, 4.0, 22.0) * 0.025
    bass = _osc(_note((36, 36, 41, 43)[int(time / 3.0) % 4]), time, "soft_square") * 0.045
    return kick + grain + bass


def _audit(time: float, _rng: random.Random) -> float:
    notes = (72, 79, 76, 83, 71, 78, 74, 81)
    step = int(time * 1.5) % len(notes)
    glass = _osc(_note(notes[step]), time) + 0.28 * _osc(_note(notes[step]) * 2.5, time)
    scan = _osc(220.0 + 36.0 * math.sin(TAU * time / 3.0), time, "triangle")
    return glass * _pulse(time, 1.5, 9.0) * 0.055 + scan * 0.020


def _walkout(time: float, rng: random.Random) -> float:
    clap = (rng.random() * 2.0 - 1.0) * _pulse(time, 1.0, 30.0) * 0.045
    response = (rng.random() * 2.0 - 1.0) * _pulse(time + 0.5, 1.0, 30.0) * 0.035
    collective = _chord(time, (48, 55, 60, 64), 0.25) * 0.075
    march = _osc(96.0, time, "triangle") * _pulse(time, 2.0, 15.0) * 0.055
    return clap + response + collective + march


TRACKS = {
    "office_base": (24.0, _base),
    "office_pressure": (12.0, _pressure),
    "office_momentum": (12.0, _momentum),
    "office_review": (16.0, _review),
    "office_ambient": (24.0, _ambient),
    "scenario_harvest": (12.0, _harvest),
    "scenario_audit": (12.0, _audit),
    "scenario_walkout": (12.0, _walkout),
}


def _write_wav(path: Path, seconds: float, renderer, seed: int) -> None:
    frame_count = round(seconds * SAMPLE_RATE)
    rng = random.Random(seed)
    frames = bytearray()
    fade_frames = max(1, int(SAMPLE_RATE * 0.06))
    for frame in range(frame_count):
        time = frame / SAMPLE_RATE
        edge = min(1.0, frame / fade_frames, (frame_count - 1 - frame) / fade_frames)
        sample = _soft_clip(renderer(time, rng)) * max(0.0, edge)
        frames.extend(struct.pack("<h", round(max(-1.0, min(1.0, sample)) * 32767.0)))
    with wave.open(str(path), "wb") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SAMPLE_RATE)
        handle.writeframes(frames)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path("assets/audio/authored_score"))
    args = parser.parse_args()
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise SystemExit("ffmpeg is required to encode the authored Ogg stems")
    args.output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="pecking-order-score-") as temp_name:
        temp = Path(temp_name)
        for index, (name, (seconds, renderer)) in enumerate(TRACKS.items()):
            wav_path = temp / f"{name}.wav"
            ogg_path = args.output / f"{name}.ogg"
            _write_wav(wav_path, seconds, renderer, 17_001 + index * 977)
            subprocess.run(
                [
                    ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(wav_path), "-c:a", "libvorbis", "-q:a", "4",
                    "-metadata", "title=Pecking Order - " + name.replace("_", " ").title(),
                    str(ogg_path),
                ],
                check=True,
            )
    print(f"AUTHORED_SCORE_BUILT tracks={len(TRACKS)} output={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
