# RTL Design and Verification

This repository is organized as a structured learning and reference base for digital design and verification. It is intended to support the full workflow from RTL design in Verilog to advanced verification in SystemVerilog and UVM, with coverage, self-checking testbenches, and reusable examples.

The goal is to keep the repository useful for daily learning, documentation, and future reference while preserving the existing work already present in the repository.

## Repository purpose

This repository is designed for:

- RTL design and implementation in Verilog
- Combinational and sequential logic design exercises
- Self-checking Verilog testbenches
- SystemVerilog language learning and verification concepts
- Object-oriented verification components
- Functional coverage and code coverage understanding
- UVM-based verification flow
- End-to-end design and verification project development

## Learning progression

1. Verilog RTL fundamentals
2. Verilog testbenches and self-checking methodology
3. SystemVerilog data types, interfaces, and procedural constructs
4. OOP-based verification components and constrained-random stimulus
5. Functional coverage and code coverage analysis
6. UVM environment and testbench architecture
7. Complete design-verification projects and reusable reference examples

## Repository structure

```text
rtl/
  combinational/
  sequential/
  memories/

verification/
  verilog/
  systemverilog/
  uvm/

coverage/
  functional/
  code/

projects/
  beginner/
  intermediate/
  advanced/

docs/
  setup/
  standards/
  references/

practice-log/
  daily-notes/

scripts/
  sim/
  compile/

systemverilog/
  datatypes/
  randomization/
```

## Work methodology

Each topic should follow a clear pattern:

- Design description
- RTL implementation
- Testbench development
- Simulation and result checking
- Coverage review
- Documentation of observations and improvements

This makes the repository a useful reference for both learning and later review.

## Example folder pattern

```text
rtl/combinational/half_adder/
  half_adder.v
  tb_half_adder.v
  README.md

verification/systemverilog/half_adder/
  tb_half_adder.sv
  README.md

verification/uvm/half_adder/
  uvm_env.sv
  sequence.sv
  README.md
```

## Daily workflow

- Add one small RTL design exercise per day
- Write a corresponding Verilog testbench
- Upgrade the same idea to SystemVerilog when ready
- Add a UVM version after a stable functional model is established
- Record coverage goals and observations
- Keep code organized and readable for future reference

## Notes

- Existing repository content is preserved.
- New content is added in a structured, incremental manner.
- This repository is intended to serve as a reference and learning archive for digital design and verification work.

## Project naming convention

Use standard, descriptive names such as:

- `half_adder`
- `mux_2to1`
- `fifo_async`
- `counter_4bit`
- `fsm_traffic_light`
- `adder_8bit`
- `scoreboard_example`
- `uvm_basic_agent`

This keeps the repository clear and professional for personal study and future reference.
