### Module 8 (Class): Standard Cell Design — SPICE Characterization & Layout

CONTENTS
1. SPICE Simulation of CMOS Inverter
2. Standard Cell Layout Design

This section goes inside a standard cell to see how its core electrical behavior is verified in SPICE, and how its physical layout is constructed transistor-by-transistor, layer-by-layer, following the SKY130 process.

---

#### 1. SPICE Simulation of CMOS Inverter
**What it is:** Before a standard cell's layout is even drawn, its core electrical behavior is verified and characterized using **SPICE** (Simulation Program with Integrated Circuit Emphasis) — a circuit-level simulator that models transistors using their actual physical/electrical equations, not just Boolean logic.

**Why start with a CMOS inverter:** The inverter is the simplest possible CMOS gate (one PMOS, one NMOS) and serves as the standard reference circuit for characterizing a technology's electrical behavior — its properties generalize to understanding every other standard cell.

**Key concepts covered:**
- **IO Placer Revision:** A quick refresher on I/O/pin placement concepts (from the physical design flow) before diving into cell-level SPICE work, to keep the full RTL-to-GDSII context in mind.
- **SPICE Deck Creation:** Writing a text-based netlist describing the inverter's transistors, their connections, sizes (W/L ratios), and the simulation commands (DC sweep, transient analysis) to run.
- **SPICE Simulation Lab:** Running the deck through `ngspice` to generate the inverter's characteristic curves.
- **Switching Threshold (Vm):** The input voltage at which the inverter's output crosses exactly halfway between `VDD` and `GND` (i.e., `Vin = Vout`). This is a key figure of merit — it reflects how balanced the pull-up (PMOS) and pull-down (NMOS) strengths are, and directly affects noise margins.
- **Static Simulation:** DC analysis — sweeping the input voltage slowly and plotting the resulting output voltage (the VTC, or Voltage Transfer Characteristic curve) to extract Vm, noise margins, and gain.
- **Dynamic Simulation:** Transient analysis — applying a fast-switching input pulse and observing the output's propagation delay and transition time, which characterize the cell's actual switching speed.

**Example (conceptual SPICE deck structure):**
```spice
* CMOS Inverter SPICE Deck
Xmp1 out in vdd vdd pmos W=1u L=0.15u
Xmn1 out in 0 0 nmos W=0.5u L=0.15u
Vdd vdd 0 1.8
Vin in 0 PULSE(0 1.8 0 0.1n 0.1n 2n 4n)
.tran 0.01n 10n
.dc Vin 0 1.8 0.01
.end
```
Running the `.dc` analysis produces the VTC curve (for Vm extraction); running the `.tran` analysis produces the switching waveform (for delay/transition extraction).

---

#### 2. Standard Cell Layout Design
**What it is:** The physical construction of a standard cell — translating the SPICE-verified transistor-level circuit into an actual geometric layout, built up layer by layer according to the SKY130 process's fabrication steps.

**The layout formation sequence (mirroring real fabrication steps):**
1. **Active Regions:** Define the regions on the silicon substrate where transistors will actually be built (where the gate oxide and source/drain diffusions will form) — everywhere else is covered by field oxide (isolation).
2. **N-well and P-well Formation:** Define the doped well regions that host PMOS transistors (inside an N-well, on a P-substrate process) and NMOS transistors (inside a P-well) — this is what allows both transistor types to coexist on the same chip.
3. **Gate Terminal Formation:** Define the polysilicon (or metal-gate) layer that forms the transistor's gate, sitting above the thin gate oxide, controlling the channel beneath it.
4. **Lightly Doped Drain (LDD) Formation:** A lightly-doped region added adjacent to the gate, before the main source/drain implant — this reduces the electric field near the drain edge, mitigating hot-carrier degradation and improving transistor reliability.
5. **Source-Drain Formation:** The heavily doped source and drain regions are implanted, completing the basic transistor structure (gate, source, drain, and the channel between them).
6. **Local Interconnect Formation:** The first layer of low-level metal/contact used to connect nearby transistor terminals together directly (e.g., connecting a PMOS and NMOS drain to form the output node of the inverter).
7. **Higher-Level Metal Formation:** Additional metal layers (M1, M2, etc.) are added above the local interconnect to route signals, power, and ground both within the cell and eventually between cells.
8. **Standard Cell Layout Assembly:** With all layers formed, the process results in a complete, DRC-clean standard cell layout — a small, tileable rectangular block adhering to the technology's standard cell height, ready to be placed and routed like any other library cell.

**Why this matters:** This is literally what happens, layer by layer, when a foundry fabricates the transistors that make up every AND gate, flip-flop, and mux used throughout the entire RTL-to-GDSII flow (Module 6) — this is the physical reality underneath the abstract `.lib`/`.lef` models used in synthesis and place-and-route.
