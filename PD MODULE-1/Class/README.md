### Module 1 (Class): From Software to Silicon — The RTL-to-GDSII Flow

CONTENTS
1. RISC-V
2. How a Software Application Produces a Hardware Output
3. Digital ASIC Design (RTL Input, EDA Tools, PDK Data)
4. RTL to GDSII Flow

This section zooms out from individual RTL coding constructs to the big picture: how a full digital ASIC — from a real, open-source instruction set like RISC-V, down to physical silicon — actually gets built.

---

#### 1. RISC-V
**What it is:** RISC-V is a free, open-source **Instruction Set Architecture (ISA)** — a specification that defines the set of instructions a processor understands (e.g., `ADD`, `LOAD`, `BRANCH`), without dictating any particular implementation.

**Why it matters for this program:**
- **Open and Royalty-Free:** Unlike proprietary ISAs (x86, ARM), RISC-V can be implemented, modified, and fabricated by anyone without licensing fees — making it the standard teaching and research platform for chip design.
- **Modular:** RISC-V has a small mandatory base instruction set (e.g., `RV32I` — 32-bit integer base), with optional extensions (multiplication `M`, atomics `A`, floating point `F`/`D`, compressed instructions `C`) that can be added as needed.
- **Real-World Relevance:** RISC-V cores are now used in real commercial chips (from embedded microcontrollers to data center accelerators), making it a practical, industry-relevant target for learning the complete RTL-to-silicon flow.

**In this program:** RISC-V serves as the reference architecture whose RTL design (like an `RV32I` core) is carried through the entire flow — from Verilog, through synthesis, through physical design — to demonstrate a complete, realistic chip design process end-to-end.

---

#### 2. How a Software Application Gives a Hardware Output
**The core idea:** Every piece of software you run — an app, an OS, a script — ultimately becomes a sequence of binary instructions that are *physically executed* by transistors switching on a chip. Understanding this layered translation is key to understanding why RTL design even matters.

**The stack, top to bottom:**
1. **Application Software:** High-level code (e.g., Python, C++) written to solve a real-world problem.
2. **Compiler:** Translates high-level code into **machine instructions** specific to a target ISA (e.g., RISC-V assembly → RISC-V machine code).
3. **Instruction Set Architecture (ISA):** The contract between software and hardware — defines exactly what instructions the hardware must be able to execute (e.g., RISC-V `RV32I`).
4. **RTL (Hardware Description):** Verilog/VHDL code that implements a processor microarchitecture capable of executing that ISA — this is where hardware design begins.
5. **Gates & Netlist:** RTL is synthesized into a gate-level netlist of standard cells.
6. **Physical Layout (GDSII):** The netlist is placed and routed into an actual physical chip layout.
7. **Silicon:** The layout is fabricated into a real physical chip — transistors that switch on/off based on voltage, physically executing the original software's instructions.

**Why this matters:** Each layer is an abstraction over the one below it. As an RTL designer, your job sits right at the hardware/software boundary — translating an ISA specification into a working, synthesizable digital circuit that a compiler's output can actually run on.

---

#### 3. Digital ASIC Design (RTL Input, EDA Tools, PDK Data)
**What it is:** A Digital ASIC (Application-Specific Integrated Circuit) design flow takes three essential inputs and combines them, using automated software, to produce a manufacturable chip.

The three key inputs:
- **RTL (Register Transfer Level):** The Verilog design describing the chip's intended functional behavior — this is what you, the designer, write.
- **EDA Tools (Electronic Design Automation):** The software toolchain that automates the entire flow — synthesis (e.g., Yosys), placement & routing (e.g., OpenROAD), timing analysis (e.g., OpenSTA), and physical verification. These tools convert abstract RTL into a manufacturable layout without requiring engineers to manually place billions of transistors.
- **PDK (Process Design Kit):** Foundry-provided data describing exactly how a specific manufacturing process works — includes the standard cell libraries (`.lib`), layout design rules, layer stack information, and electrical models specific to that fabrication node (e.g., the open-source **SkyWater 130nm (SKY130)** PDK used throughout this program).

**How they combine:** EDA tools take your RTL as input, consult the PDK to understand what's physically realizable and how to characterize timing/power, and produce a manufacturable design as output — a GDSII file ready for fabrication.

---

#### 4. RTL to GDSII Flow
**What it is:** The complete, automated pipeline that transforms a Verilog RTL design into **GDSII** — the industry-standard file format that a semiconductor foundry uses to physically fabricate a chip.

**The major stages:**
1. **RTL Design:** Write and functionally verify the Verilog design (the modules covered in Modules 1–5).
2. **Synthesis:** Convert RTL into a gate-level netlist mapped to the PDK's standard cell library (using Yosys).
3. **Floorplanning:** Define the chip's physical boundary, core area, and placement of I/O pads and macros.
4. **Placement:** Position all standard cells within the floorplan, optimizing for area and wire length.
5. **Clock Tree Synthesis (CTS):** Build a balanced clock distribution network so the clock signal reaches every flip-flop with minimal skew.
6. **Routing:** Physically connect all placed cells using available metal layers, respecting the PDK's design rules.
7. **Static Timing Analysis (STA):** Verify the routed design meets all timing constraints (setup/hold) across process, voltage, and temperature corners.
8. **Physical Verification (DRC/LVS):** Confirm the layout obeys the foundry's manufacturing design rules (DRC) and matches the original netlist (LVS).
9. **GDSII Generation:** Export the final, verified physical layout as a GDSII file — ready to be sent to the foundry for fabrication.

**Why it matters:** This flow is what the remaining modules of the program will walk through in detail, stage by stage — taking the RISC-V RTL design (and the synthesis concepts already covered) all the way through to a physically fabricable chip layout.
