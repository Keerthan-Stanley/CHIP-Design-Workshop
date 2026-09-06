### Module 2 (Class): Floorplanning, Placement & Routing Fundamentals

CONTENTS
1. Define Height and Width
2. Define Locations of Preplaced Cells
3. Decoupling Capacitors
4. Power Planning
5. Pin Placement
6. Logical Cell Placement Blocking
7. Placement and Routing
8. Cell Design Flow

This section covers the foundational stage of Physical Design — floorplanning — where the chip's physical boundaries, macro placement, power infrastructure, and I/O locations are defined, followed by how standard cells are placed and routed to realize the synthesized netlist in silicon.

---

#### 1. Define Height and Width
**What it is:** Before any cells can be placed, the physical dimensions of the chip must be defined — specifically the **die** (the total physical chip area) and the **core** (the region inside the die where actual logic — standard cells — will be placed).

- **Die:** The outer boundary of the physical silicon chip, including space reserved for I/O pads around the edges.
- **Core:** The inner rectangular region, inside the die, where the synthesized standard cells, macros, and routing actually live.
- **Height and Width:** These are literally the physical (X, Y) dimensions of the die/core, usually measured in microns. They are calculated based on:
  - The total **area** of all standard cells in the design (derived from the gate-level netlist and the `.lib`/`.lef` area data).
  - A target **utilization factor** (what fraction of the core area should actually be filled with logic vs. left for routing/spacing) — typically 50-70% for a comfortable, routable design.
  - The **aspect ratio** (width-to-height ratio) — a ratio of 1 gives a perfect square core; other values give a rectangular shape depending on design/packaging needs.

**Example relationship:**

Core Area = Total Standard Cell Area / Utilization Factor
Width × Height = Core Area
Width / Height = Aspect Ratio

If utilization is set too high, there won't be enough free space for routing later, causing routing congestion or failure. If set too low, the chip is unnecessarily large (wasting area/cost).

---

#### 2. Define Locations of Preplaced Cells
**What it is:** "Preplaced cells" refers to large, fixed hardware blocks — typically **macros** (e.g., memory blocks, PLLs, custom IP, or large functional blocks) — that must be manually placed at specific, fixed locations in the floorplan *before* automated placement of the smaller standard cells begins.

**Why they're placed first:**
- Macros are much larger and more constrained than standard cells (fixed shape, specific pin locations), so the automated placement tool cannot intelligently position them the way it does for small, uniform standard cells.
- Their location has a major impact on downstream routing congestion, timing, and floorplan efficiency, so it requires deliberate, designer-driven placement — often near the edges of the core or clustered based on connectivity to minimize wire length to other blocks/macros they interact with.

**Typical considerations when choosing preplaced locations:**
- Minimize the distance (and therefore wire delay) between macros that communicate frequently with each other.
- Keep macros away from the physical center of small, high-density standard cell regions, since large macros there tend to create routing blockages.
- Align with any pin/interface locations to reduce unnecessary detour routing.

Once macros are preplaced and "fixed" in the floorplan, the automated placer treats them as immovable obstacles and places the remaining standard cells around them.

---

#### 3. Decoupling Capacitors
**What they are:** Decoupling capacitors (decaps) are small capacitor cells placed strategically throughout the floorplan (often near macros and standard cell rows) to stabilize the local power supply.

**Why they're needed:**
- As transistors switch rapidly, they draw sudden, brief bursts of current from the power supply network.
- The power distribution network (PDN) has parasitic resistance and inductance, so these sudden current spikes can cause a temporary **voltage droop** (IR drop) at that location on the chip.
- A decoupling capacitor acts as a small, local reservoir of charge — it sits right next to the switching logic and instantly supplies the current spike locally, without waiting for it to travel all the way from the main power source, smoothing out the voltage supplied to nearby cells.

**Where they're placed:** Typically distributed near macros (which tend to have large, bursty current demands) and interspersed among standard cell rows, so that no cell is ever too far from a local charge reservoir.

---

#### 4. Power Planning
**What it is:** The process of designing the chip's **Power Distribution Network (PDN)** — the network of metal wires that deliver power (`VDD`) and ground (`VSS`) to every single cell on the chip.

**Key components of a typical PDN:**
- **Power Rings:** A ring of `VDD`/`VSS` metal traces around the perimeter of the core, connecting to the chip's external power pads.
- **Power Straps:** Thick metal wires running across the core (usually on higher, wider metal layers) that carry power from the ring inward to the interior of the chip.
- **Standard Cell Rails:** Horizontal `VDD`/`VSS` rails built into every standard cell row, which every individual cell taps into directly.

**Why it matters:**
- **IR Drop:** As current flows through resistive metal wires, voltage drops along the way. Poor power planning can cause cells far from the power source to receive insufficient voltage, causing timing failures or functional errors.
- **Electromigration:** Excessive current density in a wire over time can physically degrade the metal, eventually causing an open circuit. Proper PDN sizing (wire widths, number of straps) prevents this.
- **Robustness:** A well-planned grid-like PDN (rings + straps + rails, often mesh-connected) ensures power reaches every cell reliably, even under worst-case switching activity.

---

#### 5. Pin Placement
**What it is:** The process of assigning physical locations, along the perimeter of the core/die, for every I/O pin (input/output signal) of the top-level design.

**Why it matters:**
- Pin locations directly affect the wire length (and therefore delay) from each I/O pin to the internal logic that uses it.
- Pins are typically placed on the edge closest to the internal logic or macro that connects to them most directly, minimizing unnecessary routing detours.
- **Grouping related signals:** Buses or related signal groups (e.g., all bits of a data bus) are often placed adjacently to simplify routing and reduce skew between related signals.
- Poor pin placement can cause severe routing congestion near certain edges of the chip, or force excessively long, high-delay nets.

**Typical placement strategy:** Pins connecting to a preplaced macro near the top edge of the floorplan, for example, are placed along the top edge of the core, directly above or near that macro, minimizing wire length between the external pin and internal connection point.

---

#### 6. Logical Cell Placement Blocking
**What it is:** The practice of defining "blockage" regions within the floorplan — areas where the automated placement tool is **not allowed** to place standard cells.

**Why blockages are needed:**
- **Around Macros:** A "halo" or keep-out margin is typically defined around preplaced macros, since cells placed too close to a macro boundary can cause routing congestion or block access to the macro's own pins.
- **Reserved Areas:** Certain regions may be intentionally reserved for future design changes, additional power structures, or specific routing channels.
- **Blockage Types:**
  - **Hard Blockage:** No cells may be placed here at all.
  - **Soft Blockage:** Cells are discouraged but not strictly forbidden — used to guide the placer's optimization without creating a hard constraint.

**Effect on the flow:** The automated placement tool treats blocked regions as unusable space and works around them, placing standard cells only in the remaining legal, unblocked area of the core.

---

#### 7. Placement and Routing
**What it is:** The two central stages of physical design that take the floorplanned chip (with macros, power, and pins defined) and actually position and interconnect every standard cell in the netlist.

- **Placement:**
  - The automated tool assigns a specific (X, Y) coordinate, within a legal standard cell row, to every cell in the gate-level netlist.
  - Optimizes primarily for minimizing total wire length and reducing congestion, while respecting all blockages and preplaced macros.
  - Often done in stages: **global placement** (rough, fast positioning to establish overall structure) followed by **detailed placement** (legalizing exact positions onto real cell rows, resolving overlaps).

- **Routing:**
  - Once cells are placed, routing creates the actual physical metal wire connections between all the pins, according to the netlist's connectivity.
  - Also done in stages: **global routing** (plans rough paths and assigns nets to routing regions) followed by **detailed routing** (creates the exact, DRC-clean metal wire geometry on specific layers).
  - Must strictly obey the PDK's design rules (minimum spacing, width, via rules) to ensure the layout is manufacturable.

**Why this stage matters:** This is where the abstract gate-level netlist finally becomes real physical geometry — the literal shapes that will exist on the fabricated silicon.

---

#### 8. Cell Design Flow
**What it is:** The process by which an individual **standard cell** itself (e.g., a single `AND2`, `NAND2`, or `DFF` cell) is designed at the transistor level, before it ever becomes an entry in a `.lib`/`.lef` library used by synthesis and place-and-route tools.

**Key stages of standard cell design:**
1. **Circuit Design:** Design the transistor-level schematic (CMOS implementation) of the logic function, choosing transistor sizes to meet target drive strength, area, and power specifications.
2. **Layout Design:** Draw the physical layout (transistor placement, metal interconnects within the cell) following the foundry's process design rules, ensuring the cell fits within a standard height (matching the technology's standard cell row height) for easy tiling.
3. **Characterization:** Simulate the cell under various PVT (Process, Voltage, Temperature) corners to extract its **timing** (delay, setup/hold), **power** (leakage, dynamic), and **noise** behavior — this data becomes the `.lib` file entry used throughout synthesis and STA.
4. **Abstraction (LEF generation):** Generate a simplified physical abstraction (`.lef`) containing just the cell's boundary, pin locations, and blockage information — enough for place-and-route tools to use the cell without needing its full internal transistor layout.

**Why this matters:** Every standard cell used throughout Modules 1–7 (in synthesis, placement, and routing) exists because it went through this exact flow beforehand — this is the "factory" that produces the building blocks the rest of the ASIC design flow depends on.
