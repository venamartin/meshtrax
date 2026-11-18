# /// script
# requires-python = ">=3.11"
# ///
"""Write the SOS alert sound: "SOS" in Morse (... --- ...), twice.

  python3 tool/make_sos_sound.py

Writes android/app/src/main/res/raw/sos_morse.wav (16-bit mono PCM). Change
the pitch or the speed here, run it again, and give the Android category in
NotificationService.sosChannelId a new id: Android keeps a category's sound
from when it was first made.
"""

import math
import struct
import wave
from pathlib import Path

PITCH_HZ = 1000
WPM = 20  # PARIS timing: one dot is 1.2 / WPM seconds
RATE = 22050
RAMP_S = 0.005  # soft edges, so the keying doesn't click
LEVEL = 0.9

OUT = Path(__file__).resolve().parent.parent / 'android/app/src/main/res/raw/sos_morse.wav'


def units() -> list[tuple[bool, int]]:
    """(tone on, length in dots) for "SOS SOS"."""
    s = [(True, 1), (False, 1), (True, 1), (False, 1), (True, 1)]
    o = [(True, 3), (False, 1), (True, 3), (False, 1), (True, 3)]
    letter_gap = [(False, 3)]
    word = s + letter_gap + o + letter_gap + s
    return word + [(False, 7)] + word


def samples() -> list[int]:
    dot = 1.2 / WPM
    ramp = int(RAMP_S * RATE)
    out: list[float] = []
    for on, length in units():
        n = int(length * dot * RATE)
        for i in range(n):
            if not on:
                out.append(0)
                continue
            edge = min(i, n - 1 - i)
            gain = 0.5 - 0.5 * math.cos(math.pi * edge / ramp) if edge < ramp else 1.0
            # A little second harmonic carries better on a phone speaker.
            t = i / RATE
            v = math.sin(2 * math.pi * PITCH_HZ * t) + 0.25 * math.sin(4 * math.pi * PITCH_HZ * t)
            out.append(gain * v)
    peak = max(abs(v) for v in out)
    return [int(32767 * LEVEL * v / peak) for v in out]


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    data = samples()
    with wave.open(str(OUT), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack(f'<{len(data)}h', *data))
    print(f'{OUT}: {len(data) / RATE:.2f} s')


if __name__ == '__main__':
    main()
