# ATOMiK Architecture: Core Latency Benchmark

> **⚠️ IP & PATENT NOTICE**
>
> This repository contains software benchmarks and validation scripts for the **ATOMiK Architecture**. The underlying architecture, logic, and methods demonstrated here are **Patent Pending**.
>
> While this code is licensed under the **BSD 3-Clause License** for evaluation and benchmarking purposes, this license **does not grant any rights, express or implied, to the associated hardware patents or the ATOMiK architecture itself.**
>
> Commercial implementation of the ATOMiK architecture requires a separate license. For licensing inquiries, please check the contact details below.

## Overview
**ATOMiK** is a new hardware architecture designed to break the memory wall by treating computation as **Transient State Evolution**. By calculating register-local deltas rather than fetching full states, we decouple processing throughput from memory bus latency.

This repository hosts the **ATOMiK Latency Test**, a Python script designed to benchmark the core algorithmic logic of the architecture. It specifically separates system overhead (Python/OS/IO) from the core logic (the Hardware Target) to demonstrate the efficiency of the underlying math.

## Validation Goals
The goal of this benchmark is to isolate the **Transient State Evolution** logic.
* **System Overhead:** Represents latency that exists in software (I/O, Python interpreter loops) but is eliminated in the hardware implementation.
* **ATOMiK Core Logic:** Represents the actual XOR-based delta math, which translates to Single-Cycle Latency (<10ns) in our Verilog simulations.

## Quick Start

### Prerequisites
* Python 3.x
* `opencv-python`
* `numpy`

```bash
pip install opencv-python numpy
```

### Running the Benchmark

You can run the benchmark in two modes:

**1. With Real Data (Recommended)**
Place a video file named `your_video.mp4` in the same directory as the script.

```bash
python atomik_latency_test.py
```

*The script will automatically detect the file and use it.*

**2. With Synthetic Data** Ensure `your_video.mp4` is **not** present in the directory.

```bash
python atomik_latency_test.py
```

*The script will generate a synthetic moving diagonal line pattern to simulate delta compression loads.*

### Interpreting the Output

The script outputs a breakdown separating overhead from logic:

```text
LATENCY BREAKDOWN (per frame):
  ATOMiK Core Logic: 0.0xxx ms  (Hardware Target)
  System Overhead:   0.xxxx ms  (Eliminated in FPGA/ASIC)
```

In the FPGA implementation (currently in development), the "System Overhead" effectively drops to near-zero, leaving only the "Core Logic" execution time.

## License

Copyright (c) 2026, [Matthew Rockwell/ Rockwell Industries LLC]  
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
