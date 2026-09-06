### Module 7 (Lab): Floorplanning, Placement & Routing Fundamentals

CONTENTS
1. Lab: Defining Die/Core Height and Width
2. Lab: Placing Preplaced Macros
3. Lab: Adding Decoupling Capacitors
4. Lab: Power Planning (PDN Generation)
5. Lab: Pin Placement
6. Lab: Placement Blockages
7. Lab: Running Placement and Routing
8. Lab: Inspecting a Standard Cell's LEF/LIB Data

This section runs through a floorplanning and place-and-route flow using OpenLANE/OpenROAD on the SKY130 PDK, applying each concept from the class section directly to a design.

---

#### 1. Lab: Defining Die/Core Height and Width

**Goal:** Run floorplanning on a synthesized netlist and observe the calculated die/core dimensions based on utilization and aspect ratio settings.

**Steps (OpenLANE `config.tcl` / interactive):**
```tcl
set ::env(FP_CORE_UTIL) 45
set ::env(FP_ASPECT_RATIO) 1
```
```bash
# Run floorplan stage
run_floorplan
```
**What to check:** Open the generated floorplan `.def` file and locate the `DIEAREA` statement — note the die width/height in microns. Compare against the total standard cell area reported in the synthesis stats, and confirm the reported utilization roughly matches your configured `FP_CORE_UTIL`.

---

#### 2. Lab: Placing Preplaced Macros

**Goal:** Manually specify fixed coordinates for a macro (e.g., an SRAM block) in the floorplan.

**Steps (macro placement config):**
```tcl
# In macro.cfg or via a placement TCL command
add_macro_placement MACRO_INST_NAME -location {100 100} -orientation N
```
```bash
run_floorplan
```
**What to check:** Open the floorplan in **Magic** or **KLayout** and visually confirm the macro appears at the specified (X, Y) location, oriented as configured, and remains fixed (not moved) in subsequent placement runs.

---

#### 3. Lab: Adding Decoupling Capacitors

**Goal:** Insert decap cells into the floorplan and confirm their placement near macros/standard cell rows.

**Steps:**
```tcl
set ::env(DECAP_CELL) "sky130_fd_sc_hd__decap_3 sky130_fd_sc_hd__decap_4"
```
```bash
run_placement
```
**What to check:** After placement, search the placement `.def` file for instances of the decap cell names — confirm multiple instances are distributed throughout the design, particularly clustered near the preplaced macro from Lab 2.

---

#### 4. Lab: Power Planning (PDN Generation)

**Goal:** Generate the power distribution network (rings, straps, rails) for the floorplan.

**Steps:**
```tcl
set ::env(FP_PDN_VWIDTH) 3.1
set ::env(FP_PDN_HWIDTH) 3.1
set ::env(FP_PDN_VPITCH) 180
set ::env(FP_PDN_HPITCH) 180
```
```bash
run_pdn
```
**What to check:** Open the resulting layout in Magic/KLayout — visually confirm the power ring around the core, straps running across the interior, and horizontal `VDD`/`VSS` rails aligned with every standard cell row.

---

#### 5. Lab: Pin Placement

**Goal:** Control I/O pin placement along specific edges of the floorplan.

**Steps:**
```tcl
set ::env(FP_IO_MODE) 1
set ::env(FP_IO_VEXTEND) 2
set ::env(FP_IO_HEXTEND) 2
```
```bash
run_io_placement
```
**What to check:** Open the floorplan `.def`/layout and confirm pins are distributed along the core edges as configured — check that pins connecting to the macro from Lab 2 land on the edge nearest to it.

---

#### 6. Lab: Placement Blockages

**Goal:** Define a keep-out (halo) region around the preplaced macro and confirm the placer avoids it.

**Steps:**
```tcl
# Define a halo margin around the macro
set ::env(FP_PDN_MACRO_HOOKS) "MACRO_INST_NAME vddio vssio vddio_1 vssio_1"
add_placement_blockage -box {90 90 210 210}
```
```bash
run_placement
```
**What to check:** After placement, inspect the layout and confirm no standard cells were placed inside the blocked coordinate box — the area should remain empty except for the macro itself and any decaps explicitly allowed there.

---

#### 7. Lab: Running Placement and Routing

**Goal:** Run the full global + detailed placement and global + detailed routing stages, and inspect the final routed layout.

**Steps:**
```bash
run_placement
run_cts
run_routing
```
**What to check:**
- After placement: check the placement `.def` for legalized, non-overlapping cell coordinates.
- After routing: open the routed layout in Magic/KLayout and visually confirm all nets are fully connected with no dangling/incomplete wires. Run a DRC check:
```bash
magic -rcfile sky130.magicrc -noconsole layout.gds drc.tcl
```
Confirm the DRC report shows zero violations.

---

#### 8. Lab: Inspecting a Standard Cell's LEF/LIB Data

**Goal:** Directly inspect the `.lef` (physical abstraction) and `.lib` (timing/power characterization) files for a single standard cell, to see the output of the cell design flow described in the class section.

**Steps:**
```bash
# View the physical abstraction (pins, boundary, blockages)
grep -A 20 "MACRO sky130_fd_sc_hd__nand2_1" /path/to/sky130_fd_sc_hd.lef

# View the timing/power characterization
grep -A 30 "cell (sky130_fd_sc_hd__nand2_1)" /path/to/sky130_fd_sc_hd__tt_025C_1v80.lib
```
**What to check:** In the `.lef` output, identify the cell's `SIZE` (height/width) and `PIN` definitions with their exact geometric locations. In the `.lib` output, identify at least one timing arc (e.g., `cell_rise`, `cell_fall`) and note that its delay values are stored as lookup tables indexed by input slew and output load — directly connecting back to the `timing.lib` concept from Module 2.
