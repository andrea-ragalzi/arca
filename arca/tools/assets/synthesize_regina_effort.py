"""Build the original placeholder Regina efforts with a voiced/noise synthesizer."""
from math import exp, pi, sin, tanh
from pathlib import Path
from random import Random
import struct
import wave

RATE = 48000
DEST = Path(__file__).resolve().parents[2] / "audio" / "regina"
CUES = {"effort": (0.25, 180, 220, 0.24), "hit": (0.19, 224, 134, 0.42), "fall": (0.29, 170, 105, 0.48)}


def render(kind, cue):
    duration, start, end, breath = cue
    random = Random(kind)
    low = phase = 0.0
    pcm = []
    for sample in range(int(duration * RATE)):
        u = sample / (duration * RATE)
        hz = start + (end - start) * u + 9 * sin(u * 4 * pi)
        phase += hz * 2 * pi / RATE
        noise = random.uniform(-1, 1)
        low += 0.19 * (noise - low)
        vowel = sum(
            sin(i * phase) * (exp(-((i * hz - (440 + 260 * u)) / 270) ** 2)
                              + 0.32 * exp(-((i * hz - 1440) / 360) ** 2)) / i**0.73
            for i in range(1, 17)
        )
        envelope = sin(pi * u)**0.63 * exp(-1.85 * u)
        signal = tanh((vowel + breath * (noise - low)) * 1.7) * envelope
        pcm.append(round(signal * 26000))
    with wave.open(str(DEST / f"{kind}.wav"), "wb") as voice:
        voice.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        voice.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))


def render_impact(kind, frequency, duration, tone):
    random = Random("impact_" + kind)
    pcm = []
    for index in range(int(duration * RATE)):
        t = index / RATE
        resonance = sin(2 * pi * frequency * t) + 0.42 * sin(2 * pi * frequency * 1.47 * t)
        shape = min(t * 1600, 1.0) * exp(-t * (45 if kind == "metal" else 75))
        value = shape * ((1 - tone) * random.uniform(-1, 1) + tone * resonance)
        pcm.append(round(15000 * tanh(value)))
    with wave.open(str(DEST / f"impact_{kind}.wav"), "wb") as impact:
        impact.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        impact.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))


if __name__ == "__main__":
    DEST.mkdir(parents=True, exist_ok=True)
    for name, values in CUES.items():
        render(name, values)
    render_impact("metal", 2210, 0.15, 0.66)
    render_impact("wall", 300, 0.08, 0.22)
    render_impact("raptor", 117, 0.09, 0.72)
