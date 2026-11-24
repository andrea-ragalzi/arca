"""Bake the two original ARCA interior loops as mono PCM."""
from math import exp, pi, sin
from pathlib import Path
from random import Random
from struct import pack
import wave

RATE = 22050
OUTPUT = Path(__file__).resolve().parents[2] / "audio" / "env"


def save(name, samples):
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as stream:
        stream.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        stream.writeframes(b"".join(pack("<h", round(sample * 32767)) for sample in samples))


def hum():
    for frame in range(4 * RATE):
        t = frame / RATE
        motor = 0.26 * sin(2 * pi * 54 * t) + 0.11 * sin(2 * pi * 108 * t)
        winding = 0.05 * sin(2 * pi * 216 * t)
        yield (motor + winding) * (0.80 + 0.13 * sin(2 * pi * 1.25 * t))


def condensate():
    rng = Random(2148)
    for frame in range(round(2.1 * RATE)):
        t = frame / RATE - 1.96
        if t < 0.0 or t > 0.13:
            yield 0.0
            continue
        transient = rng.uniform(-1, 1) * 0.12 * exp(-t * 150.0)
        resonances = 0.50 * sin(2 * pi * (1280 * t + 3200 * t * t))
        resonances += 0.19 * sin(2 * pi * 628 * t)
        yield (transient + resonances * exp(-t * 56.0)) * min(1, t * 2300)


if __name__ == "__main__":
    save("equipment_hum", hum())
    save("condensate", condensate())
