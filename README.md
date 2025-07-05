# FPGA-Based Hardware-Accelerated Matrix Multiplication on RISC-V Using Systolic Array Integration

This project demonstrates a custom hardware-accelerated matrix multiplication engine built on the open-source RISC-V architecture. By integrating a custom `matmul` instruction and offloading the computation to a systolic array implemented on FPGA, we significantly accelerate matrix-heavy workloads like scientific computing and signal processing. The system maintains instruction-level abstraction while exploiting hardware-level parallelism and pipelining.

<br>

## Overview

Matrix multiplication is a fundamental operation in scientific computing, yet its naïve \( O(n^3) \) complexity makes it computationally expensive. To address this, we extended the RV32IM RISC-V processor with a new `matmul` instruction that triggers a custom systolic array accelerator. 

The project spans complete hardware-software co-design — from modifying the RISC-V toolchain and Spike simulator to implementing the architecture on an FPGA and validating results via UART.

<br>

## Key Features

-  **Custom RISC-V Instruction (`matmul`)**  
  Added to the Decode stage of the 5-stage RV32IM pipeline and assigned a reserved CUSTOM-0 opcode.

-  **Systolic Array Accelerator**  
  A 2D array of processing elements (PEs) that perform parallel Multiply-Accumulate (MAC) operations.

-  **Instruction-Driven Control**  
  The system switches seamlessly between scalar and accelerated matrix operations based on instruction decoding.

-  **Spike Simulator and GNU Toolchain Integration**  
  Software-level modeling of the instruction enabled pre-silicon validation using C programs and inline assembly.

-  **FPGA Realization**  
  Implemented on Xilinx Nexys4 DDR FPGA using Vivado, with clocking optimization and UART-based runtime verification.

<br>

## Performance Summary

| Matrix Size | Execution Time (Systolic Array) | Execution Time (Loop-Based) | Speedup |
|-------------|----------------------------------|-------------------------------|---------|
| 3×3         | 1845 ns                          | 10215 ns                      | 5.54×   |
| 3×2         | 1330 ns                          | 7332 ns                       | 5.51×   |
| 2×2         | 923 ns                           | 3458 ns                       | 3.75×   |

Power consumption also improved, with a slight increase from 0.25 W (loop) to 0.27 W (systolic array) at 67 MHz, yielding better performance per watt.

<br>

## Toolchain & Environment

- **Architecture**: RV32IM (5-stage pipelined)
- **Hardware**: Xilinx Nexys4 DDR FPGA
- **Simulation**: Spike RISC-V Simulator
- **Compiler**: Modified RISC-V GNU Toolchain
- **Clock**: 67 MHz (via Vivado Clocking Wizard)
- **Language**: Verilog (Hardware), C (Test Programs)

<br>

## Repository Structure

The repository is structured to clearly distinguish between hardware implementations, simulations, and supporting documents. The `riscv_matmul` folder contains Verilog source files for the modified RV32IM core with an integrated systolic array accelerator and custom `matmul` instruction. In contrast, the `riscv_without_matmul` folder provides the baseline RISC-V design implementing traditional loop-based matrix multiplication. The `Readme` file offers a comprehensive overview of the project, while `SRIP_Research_Report` and `SRIP_Research_Poster` contain the detailed research report and academic poster respectively. Additionally, `Project_Documentation_RISCV_matmul` consolidates presentation materials and explanatory documents used during the project evaluation. This organization ensures clarity and ease of navigation for contributors, researchers, and reviewers.

<br>

## Future Work

- Integrate accelerator into end-to-end neural network inference pipeline.
- Extend compiler backends for automatic matmul substitution.
- Add full co-simulation support with Spike and waveform traces.

<br>

## Authors

**Anirudh Mittal**  
B.Tech Electrical Engineering  
Indian Institute of Technology Gandhinagar  
[anirudh.mittal@iitgn.ac.in](mailto:anirudh.mittal@iitgn.ac.in) 

**Arjun A. Mallya**  
B.Tech Electrical Engineering  
Indian Institute of Technology Gandhinagar  
[arjun.mallya@iitgn.ac.in](mailto:arjun.mallya@iitgn.ac.in)

**Shah Tirth**  
B.Tech Electrical Engineering  
Indian Institute of Technology Gandhinagar

[tirth.shah@iitgn.ac.in](mailto:tirth.shah@iitgn.ac.in)

<br>

## Acknowledgments

We sincerely thank our mentor **Prof. Joycee M. Mekie** for her continuous guidance and mentorship. This work was undertaken under the **Summer Research Internship Program (SRIP) 2025** at the **Indian Institute of Technology Gandhinagar**.

<br>

## License

This project is released for academic and educational purposes. Reach out to authors for any intended use beyond research or learning.

---


