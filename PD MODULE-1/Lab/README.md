### Module 6 (Lab): From Software to Silicon — The RTL-to-GDSII Flow

CONTENTS
1. Lab: Exploring the RISC-V Toolchain
2. Lab: Compiling C Code to RISC-V Machine Code
3. Lab: Setting Up the Digital ASIC Design Environment (RTL + EDA Tools + PDK)
4. Lab: Running the Complete RTL-to-GDSII Flow

This section moves from theory into hands-on setup — exploring the RISC-V toolchain, tracing a compiled program down to machine code, and running an end-to-end open-source RTL-to-GDSII flow using the SKY130 PDK.

---

#### 1. Lab: Exploring the RISC-V Toolchain

**Goal:** Set up and verify a working RISC-V GNU toolchain, confirming the tools needed to compile and inspect RISC-V programs are functional.

**Steps:**
```bash
# Verify the RISC-V GCC toolchain is installed
riscv64-unknown-elf-gcc --version

# Verify the objdump utility (for disassembly) is available
riscv64-unknown-elf-objdump --version

# Verify a simulator (e.g. Spike or an emulator) is available
spike --help
```
**What to check:** All three commands should return version/help output without errors, confirming the toolchain (compiler, disassembler, and simulator) is correctly installed and ready to use.

---

#### 2. Lab: Compiling C Code to RISC-V Machine Code

**Goal:** Trace a simple C program all the way from source code to raw RISC-V machine instructions, to see the "software to hardware instructions" translation from Topic 2 in practice.

**Source (`sum.c`):**
```c
int sum_to_n(int n) {
    int sum = 0;
    for (int i = 1; i <= n; i++)
        sum += i;
    return sum;
}

int main() {
    return sum_to_n(10);
}
```

**Steps:**
```bash
# Step 1: Compile to a RISC-V ELF binary
riscv64-unknown-elf-gcc -O1 -march=rv32i -mabi=ilp32 -o sum.o sum.c

# Step 2: Disassemble to see the generated RISC-V assembly
riscv64-unknown-elf-objdump -d sum.o
```
**What to check:** In the disassembly output, identify RV32I instructions (`add`, `addi`, `blt`, `ret`, etc.) and manually map a few lines of the C loop to their corresponding assembly instructions — directly observing the compiler's translation from high-level software down to the ISA-level instructions that hardware ultimately executes.

---

#### 3. Lab: Setting Up the Digital ASIC Design Environment (RTL + EDA Tools + PDK)

**Goal:** Set up the three essential inputs of a Digital ASIC flow — verify the RTL synthesis tool, place-and-route tool, and PDK data are all correctly installed and accessible.

**Steps:**
```bash
# Verify Yosys (synthesis EDA tool)
yosys -V

# Verify OpenROAD (place & route EDA tool), if using OpenLANE
openroad -version

# Confirm the SKY130 PDK is available
ls /path/to/sky130/sky130_fd_sc_hd/

# Inspect a sample liberty file from the PDK
head -n 20 /path/to/sky130/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
```
**What to check:** Confirm the PDK directory contains the standard cell library files (`.lib`, `.lef`, GDS files for individual cells) — these are the exact files that will be referenced throughout the physical design flow in upcoming modules.

---

#### 4. Lab: Running the Complete RTL-to-GDSII Flow

**Goal:** Run a full, end-to-end RTL-to-GDSII flow on a small design (e.g., the `good_mux` or a simple RISC-V core module) using an open-source flow manager like **OpenLANE**, to see every stage from Topic 4 execute in sequence.

**Steps:**
```bash
# Launch OpenLANE's interactive flow (or containerized environment)
cd OpenLane
make mount

# Inside the container, start the flow for a design
./flow.tcl -design your_design_name -tag run1

# Alternatively, run interactively stage by stage:
./flow.tcl -interactive
% package require openlane
% prep -design your_design_name
% run_synthesis
% run_floorplan
% run_placement
% run_cts
% run_routing
% run_magic          ;# DRC/LVS + GDS generation
```
**What to check:** After the flow completes, inspect the `runs/run1/results/final/gds/` directory for the generated `.gds` file — the final physical layout ready for fabrication. Open it in **Magic** or **KLayout** to visually inspect the placed-and-routed chip layout, and compare the reported area/timing metrics in the run's summary report against your expectations from the original RTL.
