"""Render deterministic raptor calls with a processed CC0 crow layer."""
from argparse import ArgumentParser
from hashlib import sha256
from math import exp, pi, sin
from pathlib import Path
from random import Random
import struct
import subprocess
import wave

RATE = 48000
DESTINATION = Path(__file__).resolve().parents[2] / "audio/raptor"
CROW_DIGEST = "2199bda1eaddb357371160265885008c5aebc5847e321657fecbe6c7ee62ad72"


# Each throat pulse gives duration, start pitch, end pitch, rasp and gain.
CALLS = {
    "call_01": [(0.17, 240, 420, 0.7, 0.78), (0.39, 510, 228, 0.55, 1.0)],
    "call_02": [(0.23, 191, 340, 0.66, 0.86), (0.32, 380, 205, 0.72, 1.0)],
    "reply_01": [(0.16, 308, 220, 0.49, 1.0), (0.19, 272, 160, 0.70, 0.67)],
    "reply_02": [(0.24, 365, 180, 0.55, 1.0)],
    "threat_01": [(0.34, 118, 178, 0.84, 1.0)],
}


def throat(pulse, rng):
    duration, start, end, rasp, gain = pulse
    phase = low = middle = 0.0
    samples = []
    for i in range(int(duration * RATE)):
        t = i / RATE
        u = t / duration
        base = start + (end - start) * u
        phase += 2 * pi * base * (1 + 0.06 * sin(t * 93) + 0.025 * sin(t * 241)) / RATE
        noise = rng.uniform(-1, 1)
        low += (noise - low) * 0.11
        middle += (noise - middle) * 0.34
        pulse_shape = sum(
            sin(phase * k + 0.17 * sin(phase * 0.51)) * exp(-((base * k - 1050) / 720) ** 2) / (k ** 0.71)
            for k in range(1, 10)
        )
        pulse_shape += 0.18 * sin(phase * 0.49) + 0.20 * sin(phase * 1.59)
        envelope = sin(pi * u) ** 0.67 * (0.84 + 0.16 * sin(t * 115))
        samples.append(envelope * gain * (pulse_shape * (1 - 0.45 * rasp) + (middle - low) * rasp * 1.28))
    return samples


def load_recording(source):
    if sha256(source.read_bytes()).hexdigest() != CROW_DIGEST:
        raise ValueError("Use the credited Crow 1 HQ preview recorded in ATTRIBUTIONS.md")
    raw = subprocess.check_output(
        ["ffmpeg", "-v", "error", "-i", str(source), "-ac", "1", "-ar", str(RATE), "-f", "f32le", "-"]
    )
    samples = [sample for (sample,) in struct.iter_unpack("<f", raw)]
    peak = max(abs(sample) for sample in samples)
    return [sample / peak for sample in samples]


def mix_crow(cut, recording, speed, offset, gain):
    low = middle = 0.0
    start_sample = int(offset * RATE)
    length = min(len(cut) - start_sample, int((len(recording) - 1) / speed))
    for sample in range(length):
        phase = sample * speed
        index = int(phase)
        value = recording[index] + (recording[index + 1] - recording[index]) * (phase - index)
        low += 0.034 * (value - low)
        middle += 0.18 * (value - middle)
        envelope = min(1.0, sample / 750, (length - sample) / 1600)
        cut[start_sample + sample] += gain * envelope * (0.42 * value + 1.5 * (middle - low))


def build(recording):
    animal_layers = ((0.58, 0.07, 0.79), (0.66, 0.04, 0.74), (0.81, 0.00, 0.52),
                     (0.90, 0.02, 0.52), (0.46, 0.00, 0.41))
    for index, (name, pulses) in enumerate(CALLS.items()):
        rng = Random(7193 + index)
        cut = []
        for pulse in pulses:
            if cut:
                cut.extend([0.0] * int(0.052 * RATE))
            cut.extend(throat(pulse, rng))
        mix_crow(cut, recording, *animal_layers[index])
        peak = max(abs(sample) for sample in cut)
        with wave.open(str(DESTINATION / f"{name}.wav"), "wb") as cue:
            cue.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
            cue.writeframes(b"".join(struct.pack("<h", round(sample / peak * 28000)) for sample in cut))


if __name__ == "__main__":
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("crow", type=Path, help="Credited Freesound HQ preview (MP3)")
    build(load_recording(parser.parse_args().crow))
