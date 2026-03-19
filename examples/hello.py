#!/usr/bin/env python3
"""Hello World — Python on MerlionOS."""

import sys
import os
import time

print("Hello from Python on MerlionOS!")
print(f"Python {sys.version}")
print(f"Platform: {sys.platform}")
print(f"PID: {os.getpid()}")
print(f"CWD: {os.getcwd()}")

# File I/O
with open("/tmp/python_test.txt", "w") as f:
    f.write("Python file I/O works on MerlionOS!\n")

with open("/tmp/python_test.txt") as f:
    print(f"File: {f.read().strip()}")

# Data structures
data = {"os": "MerlionOS", "lang": "Python", "year": 2026}
print(f"Dict: {data}")

nums = [x**2 for x in range(10)]
print(f"Squares: {nums}")

# Timing
start = time.monotonic()
time.sleep(0.1)
elapsed = time.monotonic() - start
print(f"Slept {elapsed:.3f}s")

print("All Python tests passed!")
