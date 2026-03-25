#!/usr/bin/env python3

import os
import numpy as np
import matplotlib.pyplot as plt

# ============================
# CONFIG
# ============================

BASE_DIR = "<dir path>"
EVENTS_PATH = os.path.join(BASE_DIR, "lte_events.dat")
POWER_PATH = os.path.join(BASE_DIR, "lte_power.dat")

EVENTI_ATTESI = 17 # to change 

CHUNK_SIZE = 10_000_000
MAX_POINTS = 200_000

# ============================
# 1. CONTA EVENTI (STREAMING)
# ============================

detected_events = 0
prev_last = 0

print("Analysis of ongoing events...")

with open(EVENTS_PATH, "rb") as f:
    while True:
        data = np.fromfile(f, dtype=np.uint8, count=CHUNK_SIZE)
        if len(data) == 0:
            break

        binary = data > 0
        edges = np.diff(binary.astype(np.int8)) == 1
        detected_events += int(edges.sum())

        if binary[0] == 1 and prev_last == 0:
            eventi_rilevati += 1

        prev_last = int(binary[-1])

# ============================
# 2. BLER-LIKE
# ============================

bler_like = max(0.0, (EXPECTED_EVENTS - detected_events) / EXPECTED_EVENTS)

print("\n=== Results ===")
print("EXPECTED EVENTS:", EXPECTED_EVENTS)
print("DETECTED EVENTS:", detected_events)
print("BLER-like:", round(bler_like * 100, 2), "%")

# ============================
# 3. GRAFICO POWER
# ============================

print("\nPower Chart Generation...")

power_size = os.path.getsize(POWER_PATH)
power_len = power_size // 4  # float32

power = np.memmap(POWER_PATH, dtype=np.float32, mode='r', shape=(power_len,))

if power_len > MAX_POINTS:
    step = power_len // MAX_POINTS
    power_view = power[::step]
else:
    power_view = power

power_png = os.path.join(BASE_DIR, "lte_power_plot.png")

plt.figure(figsize=(12, 4))
plt.plot(power_view)
plt.title("LTE Power (downsampled)")
plt.grid(True)
plt.tight_layout()
plt.savefig(power_png, dpi=150)
plt.close()

# ============================
# 4. GRAFICO EVENTI
# ============================

print("Generate an event chart...")

events_size = os.path.getsize(EVENTS_PATH)
events_len = events_size

events = np.memmap(EVENTS_PATH, dtype=np.uint8, mode='r', shape=(events_len,))

if events_len > MAX_POINTS:
    step = events_len // MAX_POINTS
    events_view = events[::step]
else:
    events_view = events

events_png = os.path.join(BASE_DIR, "lte_events_plot.png")

plt.figure(figsize=(12, 3))
plt.plot(events_view)
plt.title("LTE Events (downsampled)")
plt.grid(True)
plt.tight_layout()
plt.savefig(events_png, dpi=150)
plt.close()

# ============================
# 5. INTERPRETAZIONE
# ============================

print("\n=== INTERPRETATION ===")

if bler_like < 0.05:
    print("Very good correlation")
elif bler_like < 0.15:
    print("Good/fair correlation")
elif bler_like < 0.30:
    print("Weak correlation")
else:
    print("Weak correlation - review threshold or frequency")

print("\nGenerated files:")
print(power_png)
print(events_png)
