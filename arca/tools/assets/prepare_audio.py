#!/usr/bin/env python3
"""Build ARCA's sprint cues from the approved inputs in a local staging folder."""

import argparse
import math
from pathlib import Path
import random
import struct
import subprocess
import wave

RATE = 48_000
PEAK_PCM = 29_000
ROOT = Path(__file__).resolve().parents[3]

# Timing is measured in the decoded HQ previews.
CUTS = {
    "raptor/roar_01": ("raptor", 0.23, 0.73),
    "raptor/roar_02": ("raptor", 1.39, 0.71),
    "raptor/hurt_01": ("raptor", 2.38, 0.24),
    "raptor/hurt_02": ("raptor", 7.65, 0.34),
    "raptor/death_01": ("raptor", 10.92, 0.55),
    "raptor/breath_01": ("raptor", 4.45, 2.78),
    "raptor/bite_01": ("bite", 0.0, 0.3),
    "raptor/footstep_01": ("steps", 4.43, 0.22),
    "raptor/footstep_02": ("steps", 4.93, 0.32),
    "raptor/footstep_03": ("steps", 6.55, 0.31),
    "env/ambience_01": ("ambience", 0.0, 7.735),
}
SYNTH = {
    "env/alarm_01": 2.4,
    "door/servo_open_01": 0.98,
    "door/locked_deny_01": 0.25,
    "ui/keycard_accept_01": 0.30,
    "ui/note_open_01": 0.32,
}
LOOPS = {"raptor/breath_01", "env/ambience_01", "env/alarm_01"}


def decode(path, start, duration):
    raw = subprocess.check_output([
        "ffmpeg", "-v", "error", "-ss", str(start), "-i", str(path),
        "-t", str(duration), "-ac", "1", "-ar", str(RATE),
        "-f", "s16le", "-acodec", "pcm_s16le", "-",
    ])
    return [sample[0] / 32768 for sample in struct.iter_unpack("<h", raw)]


def synthesize(cue, duration):
    samples = []
    rng = random.Random(431)
    for frame in range(round(duration * RATE)):
        t = frame / RATE
        if cue == "env/alarm_01":
            envelope = (max(0.0, math.sin(math.tau * t / 1.2))) ** 2
            sample = envelope * (math.sin(math.tau * 520 * t) + 0.35 * math.sin(math.tau * 780 * t))
        elif cue == "door/servo_open_01":
            phase = math.tau * (85 * t + 22 * t * t)
            sample = math.sin(phase) + 0.25 * math.sin(2.03 * phase) + rng.uniform(-0.18, 0.18)
        elif cue == "door/locked_deny_01":
            sample = (math.sin(math.tau * 142 * t) + 0.36 * math.sin(math.tau * 218 * t))
            sample *= math.exp(-8 * t)
        elif cue == "ui/keycard_accept_01":
            elapsed = t % 0.15
            frequency = 640 if t < 0.15 else 880
            sample = math.sin(math.tau * frequency * elapsed) * math.sin(math.pi * elapsed / 0.15)
        else:
            sample = rng.uniform(-1, 1) * (abs(math.sin(math.tau * 5 * t)) ** 3) * math.exp(-7 * t)
        samples.append(sample)
    return samples


def crossfade_loop(samples, fade_seconds):
    span = round(fade_seconds * RATE)
    for index in range(span):
        weight = index / (span - 1)
        samples[index] = samples[index - span] * (1.0 - weight) + samples[index] * weight
    return samples[:-span]


def taper(samples):
    span = round(0.015 * RATE)
    for index in range(span):
        gain = index / span
        samples[index] *= gain
        samples[-index - 1] *= gain
    return samples


def save(cue, samples):
    peak = max(abs(sample) for sample in samples)
    gain = PEAK_PCM / peak
    path = ROOT / "arca" / "audio" / (cue + ".wav")
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = [round(sample * gain) for sample in samples]
    with wave.open(str(path), "wb") as output:
        output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        output.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))
    peak_db = 20 * math.log10(max(map(abs, pcm)) / 32768)
    print(f"| {cue} | {path.relative_to(ROOT)} | {len(pcm) / RATE:.3f} | "
          f"{'Forward' if cue in LOOPS else 'No'} | {peak_db:.2f} |")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("staging", type=Path)
    args = parser.parse_args()
    for cue, (source, start, duration) in CUTS.items():
        samples = decode(args.staging / (source + ".mp3"), start, duration)
        samples = crossfade_loop(samples, 0.12) if cue in LOOPS else taper(samples)
        save(cue, samples)
    for cue, duration in SYNTH.items():
        samples = synthesize(cue, duration)
        save(cue, samples if cue in LOOPS else taper(samples))


if __name__ == "__main__":
    main()
