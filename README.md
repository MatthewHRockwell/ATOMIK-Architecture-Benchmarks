# ATOMiK Architecture  
## Hardware-Native Transient State Computation


> **IP & PATENT NOTICE**

This repository contains software benchmarks, hardware description language (HDL) implementations, and validation artifacts for the **ATOMiK Architecture**.

The underlying architecture, execution model, and methods demonstrated here are **Patent Pending**.

While source code in this repository may be licensed under the **BSD 3-Clause License** for evaluation, testing, and benchmarking purposes, **no rights—express or implied—are granted to the underlying ATOMiK hardware architecture, execution model, or associated patents**.

Commercial use, hardware integration, or derivative architectural implementations require a separate license.

---

## Overview

**ATOMiK** is a stateless, hardware-native compute architecture that reframes computation as **transient state evolution** rather than persistent state storage.

Instead of repeatedly loading, storing, and reconciling full system state, ATOMiK operates exclusively on **register-local deltas**—capturing only what has changed, when it changed, and how it evolved. This approach:

- Breaks the memory wall
- Minimizes data movement
- Enables nanosecond-scale decision latency
- Eliminates entire classes of state-based security vulnerabilities

This repository documents both:

1. **Software-based validation** of the ATOMiK execution model (Python)
2. **Hardware-native implementations** targeting FPGA (Verilog)

The Python components exist solely to validate correctness, compression behavior, and delta algebra. The Verilog implementation reflects the intended production execution path.

---

## Repository Structure

```text
ATOMiK/
├── hardware/
│   ├── src/            # Verilog source (ATOMiK core, UART, glue logic)
│   ├── tb/             # Testbenches and simulation harnesses
│   └── constraints/    # FPGA constraint files (Tang Nano)
├── software/
│   └── atomik_latency_test.py  # Software validation + latency breakdown
├── docs/
│   └── uart_simulation.png     # Simulation output (UART / core timing)
└── README.md
```

<div align="center">
<video src="https://github.com/user-attachments/assets/06de6427-d917-4722-9129-266b6e87520f" width="600" controls></video>
</div>
