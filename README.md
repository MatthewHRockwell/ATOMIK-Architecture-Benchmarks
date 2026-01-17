# ATOMiK Architecture

## Hardware‑Native Transient State Computation

> **IP & PATENT NOTICE**
>
> This repository contains software benchmarks, hardware description language (HDL) implementations, and validation artifacts for the **ATOMiK Architecture**.
>
> The underlying architecture, execution model, and methods demonstrated here are **Patent Pending**.
>
> While the source code in this repository may be licensed under the **BSD 3‑Clause License** for evaluation, testing, and benchmarking purposes, **no rights—express or implied—are granted to the underlying ATOMiK hardware architecture, execution model, or associated patents**.
>
> Commercial use, hardware integration, or derivative architectural implementations require a separate license.

---

## Architectural Abstract

**ATOMiK** is a hardware-native compute architecture that replaces persistent architectural state with **transient state evolution**. Computation is expressed as bounded, deterministic delta propagation across register-local state, eliminating bulk memory traffic, cache coherency overhead, and speculative execution. The result is a cycle-bounded execution model capable of nanosecond-scale decision latency, well-suited for FPGA and ASIC implementation where determinism, security, and energy efficiency are first-order constraints.

---

## Overview

**ATOMiK** is a stateless, hardware‑native compute architecture that reframes computation as **transient state evolution** rather than persistent state storage.

Instead of repeatedly loading, storing, and reconciling full system state, ATOMiK operates exclusively on **register‑local deltas**—capturing only what has changed, when it changed, and how it evolved. Computation is performed as a bounded sequence of deterministic state transitions that exist only long enough to produce a result.

This execution model:

* Breaks the classical memory wall by eliminating bulk memory traffic
* Minimizes data movement and external memory dependencies
* Enables deterministic, nanosecond‑scale decision latency
* Eliminates entire classes of state‑based security vulnerabilities
* Maps naturally to FPGA fabric without cache hierarchies or speculation

This repository serves as a **benchmark and validation harness**, not a full product release. It demonstrates how the ATOMiK execution model behaves under simulation, how it maps to hardware, and how latency scales when computation is expressed as transient delta propagation.

---

## Execution Model Summary

At a high level, ATOMiK operates under the following principles:

1. **No Persistent Architectural State**
   The core does not maintain long‑lived global state. All computation occurs within tightly scoped register windows.

2. **Delta‑Only Propagation**
   Inputs are treated as deltas rather than full state vectors. Only the minimal information required to advance computation is propagated.

3. **Cycle‑Bounded Evaluation**
   Each computation completes in a known, bounded number of clock cycles, independent of historical system state.

4. **Hardware‑First Semantics**
   The Verilog implementation is the reference execution path. Software models exist only to validate correctness and measurement.

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

---

## Hardware Implementation Details

### Core Logic (`hardware/src`)

The hardware directory contains a minimal but representative ATOMiK datapath:

* **`atomik_core.v`**
  Implements the transient state execution engine. This module is responsible for accepting delta inputs, performing bounded combinational/sequential evaluation, and emitting result deltas without retaining historical context.

* **`atomik_top.v`**
  Top‑level integration wrapper that binds the ATOMiK core to external interfaces and simulation infrastructure.

* **`atomik_uart_mvp_top.v`**
  Minimal viable FPGA top used to serialize ATOMiK outputs over UART for real‑time observation and benchmarking.

* **`uart_tx.v` / `uart_rx_sim.v`**
  Lightweight UART transmitter and simulation‑side receiver used strictly for visibility and measurement. These are not part of the core execution model.

The design intentionally avoids caches, DMA engines, or external memory controllers to ensure measured latency reflects **pure compute behavior**, not I/O artifacts.

---

### Testbenches (`hardware/tb`)

* **`tb_uart_mvp.v`**
  End‑to‑end simulation harness that drives stimulus into the ATOMiK core and captures serialized output via UART.

* **`stimulus_gen.v`**
  Deterministic stimulus generator used to inject controlled delta patterns and measure cycle‑accurate response.

Simulation is typically performed using **Icarus Verilog + GTKWave**, allowing direct inspection of transient internal signals and cycle boundaries.

---

### FPGA Constraints (`hardware/constraints`)

* **`tang_nano.cst`**
  Pin and clock constraints targeting the Sipeed Tang Nano FPGA platform. This file is provided to enable rapid hardware bring‑up and should be considered reference‑only.

---

## Software Validation

The Python benchmark (`atomik_latency_test.py`) exists to:

* Validate functional equivalence with the hardware execution model
* Measure theoretical latency bounds
* Provide a human‑readable breakdown of delta propagation timing

It is **not** intended to represent performance parity with the FPGA implementation. The hardware path is the authoritative reference.

---

## Simulation & Demo

The included demo video shows a complete simulation loop:

<div align="center">
<video src="https://github.com/user-attachments/assets/06de6427-d917-4722-9129-266b6e87520f" width="600" controls></video>
</div>

* Deterministic stimulus injection
* Transient state evaluation inside the ATOMiK core
* UART-serialized output
* Waveform inspection in GTKWave

This setup is intentionally minimal to highlight architectural behavior rather than system integration complexity.

---

## Latency Envelope (Representative)

The following table summarizes **cycle-level latency behavior** observed under simulation. Values are representative and depend on clock frequency and target device; no internal mechanisms are disclosed.

|                    Stage | Description                 |     Cycles     |
| -----------------------: | --------------------------- | :------------: |
|              Input Latch | Delta capture               |        1       |
|          Core Evaluation | Transient state propagation | O(1–N) bounded |
|            Result Commit | Output stabilization        |        1       |
| Serialization (Optional) | UART visibility only        |    Variable    |

Key properties:

* Latency is **bounded and deterministic**
* No dependency on prior execution history
* No cache warm-up, page faults, or speculative rollback

---

## Audience Alignment

This README is intentionally written to serve **three distinct but overlapping audiences**. Each section is structured so that readers can extract value without requiring full-domain overlap.

### FPGA & Hardware Engineers

* Clear module boundaries and signal-level intent
* Cycle-bounded execution semantics
* Simulation-first validation with real FPGA constraints
* No hidden software abstraction layers

If you are evaluating feasibility, timing behavior, or architectural novelty at the RTL level, the **Hardware Implementation** and **Testbench** sections are the authoritative reference.

### Researchers & Technical Reviewers

* Explicit execution model definition
* Deterministic, stateless computation semantics
* Separation of validation tooling from reference execution
* Architecture-first framing independent of vendor tooling

If you are reviewing ATOMiK as a **computational model** or architectural primitive, focus on the **Execution Model Summary** and how transient state replaces persistent architectural state.

### Investors & Strategic Partners

* Clear differentiation from CPUs, GPUs, and accelerators
* Bounded latency and deterministic behavior
* Hardware-native scalability path
* Strong IP and licensing posture

If you are evaluating ATOMiK from a commercialization or infrastructure perspective, the **Overview**, **Simulation & Demo**, and **Licensing** sections provide the relevant framing.

---

## What ATOMiK Is — and Is Not

**ATOMiK is:**

* A hardware-native transient state compute architecture
* A deterministic, cycle-bounded execution model
* A platform for ultra-low-latency decision logic
* A foundational primitive intended for integration into larger systems

**ATOMiK is not:**

* A general-purpose CPU or soft-core processor
* A GPU, NPU, or data-parallel accelerator
* A firmware-driven state machine
* A software-emulated architecture

ATOMiK occupies a distinct point in the compute design space: **where computation is expressed as ephemeral state evolution rather than stored program execution**.

---

## System Integration Model

ATOMiK is designed to function as a **computational primitive**, not a monolithic processor. Typical integration patterns include:

* Inline decision engines on high-speed data paths
* Deterministic control logic in safety- or latency-critical systems
* Pre-filter or arbitration layers ahead of general-purpose compute
* Hardware-native inference, compression, or rule-evaluation blocks

ATOMiK intentionally omits:

* Instruction fetch/decode pipelines
* Virtual memory or address translation
* Cache hierarchies and coherency protocols

This makes it complementary to existing compute systems rather than competitive with them.

---

## Platform Vision

ATOMiK is not positioned as a single-purpose accelerator or fixed-function block. It is intended to evolve into a **foundational compute platform** whose execution semantics can be embedded across software and hardware boundaries.

The current FPGA implementation represents the **root system**: a validated, deterministic execution core. From this base, higher-order abstractions can be layered without compromising the underlying transient-state guarantees.

Long-term, ATOMiK is designed to support:

* **Pipeline SDKs** for direct integration into existing dataflows
* **System-level orchestration layers** that expose transient-state execution as a first-class primitive
* **Distributed coordination models** built on deterministic state evolution
* **AI, control, and cryptographic workloads** that benefit from bounded latency and stateless semantics

This evolution is deliberate: hardware first, abstraction second.

---

## Roadmap

### Near-Term (Current Focus)

* FPGA validation and timing closure
* Expanded benchmark coverage
* Debugging and formal verification artifacts
* Clean, minimal interfaces suitable for SDK binding

### Mid-Term

* Language-agnostic SDKs for pipeline integration
* Hardware-software co-simulation tooling
* Multi-instance composition models
* Early ASIC feasibility exploration

### Long-Term Platform Trajectory

* **Operating system primitives** built around transient execution
* **Deterministic distributed systems** and blockchain-like coordination layers
* **AI execution substrates** where inference is expressed as delta propagation
* **Composable infrastructure** rather than monolithic products

ATOMiK is intended to grow **vertically** (depth of capability) rather than horizontally (feature sprawl), preserving architectural coherence as it scales.

---

## Architectural Discipline

While the platform vision is expansive, ATOMiK enforces strict architectural discipline:

* Hardware semantics remain canonical
* Abstractions must preserve determinism
* No retrofitting of legacy execution models
* No dilution into general-purpose compute paradigms

This discipline is what allows ATOMiK to scale from a single FPGA core to a platform-level foundation without collapsing under complexity.

---

## Intended Use

This repository is intended for:

* Architectural evaluation and peer review
* FPGA-level benchmarking and latency measurement
* Validation of transient-state compute models
* Investor, partner, and technical due-diligence review

It is **not** intended as a drop-in accelerator, soft-core CPU, or general-purpose compute platform.

---

## Licensing & Contact

Source files are provided under the BSD 3-Clause License **for evaluation only**, subject to the patent notice above.

For licensing inquiries, commercial integration, or architectural collaboration, please contact the repository owner.
