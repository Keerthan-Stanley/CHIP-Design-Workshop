### Module 8 (Lab): Standard Cell Design — SPICE Characterization & Layout

CONTENTS
1. Lab: SPICE Simulation of CMOS Inverter
2. Lab: Standard Cell Layout Construction

This section walks through characterizing a CMOS inverter in ngspice and building its layout in Magic from the ground up, layer by layer, following the SKY130 process.

---

#### 1. Lab: SPICE Simulation of CMOS Inverter

**Goal:** Write and simulate a SPICE deck for a CMOS inverter, extract its switching threshold (Vm), and observe both static and dynamic behavior.

**Steps:**
```bash
# Step 0: IO placer revision — quick recap before cell-level work
cat io_placer.tcl

# Step 1: Create the SPICE deck for the CMOS inverter
cat > inverter.spice << 'EOF'
* CMOS Inverter
.include sky130_fd_pr_models.spice
Xmp1 out in vdd vdd sky130_fd_pr__pfet_01v8 W=1 L=0.15
Xmn1 out in 0 0 sky130_fd_pr__nfet_01v8 W=0.5 L=0.15
Vdd vdd 0 1.8
Vin in 0 0
.dc Vin 0 1.8 0.01
.tran 0.01n 10n
.control
run
plot out vs in
.endc
.end
EOF

# Step 2: Run the static (DC) simulation
ngspice inverter.spice
```
**What to check:** From the DC sweep plot (VTC curve), find the point where `Vout = Vin` — this is the switching threshold `Vm`. Confirm it's roughly centered (near `VDD/2` for a well-balanced inverter), and note any shift if PMOS/NMOS sizing is unbalanced.

**Dynamic simulation:**
```bash
# Modify Vin to a pulse source for transient simulation
sed -i 's/Vin in 0 0/Vin in 0 PULSE(0 1.8 0 0.1n 0.1n 2n 4n)/' inverter.spice
ngspice inverter.spice
```
**What to check:** Measure the propagation delay (`tpHL`, `tpLH`) between the input and output crossing 50% `VDD`, and the output transition time — this is the raw switching-speed data that characterizes the inverter's dynamic behavior.

**Git clone step (for the layout lab that follows):**
```bash
git clone https://github.com/nickson-jose/vsdstdcelldesign
cd vsdstdcelldesign
```

---

#### 2. Lab: Standard Cell Layout Construction

**Goal:** Build a standard cell layout in Magic, following the SKY130 process's layer-by-layer formation sequence, and verify it against the SPICE deck from Lab 1.

**Steps:**
```bash
# Open the layout in Magic with the SKY130 tech file
magic -rcfile sky130A.magicrc sky130_inv.mag
```

**Inside Magic, work through the layer sequence:**
1. Draw the **active regions** (`ndiff`/`pdiff`) rectangles.
2. Draw the **N-well** (`nwell`) around the PMOS active region.
3. Draw the **poly** layer to form the transistor **gates**.
4. Let the tech file's implant rules auto-generate the **LDD** regions (or draw the LDD layer manually if required).
5. Form the **source/drain** regions and place contact cuts (`licon`).
6. Draw **local interconnect** (`li1`) to tie the PMOS/NMOS drains together at the output node.
7. Add **higher-level metal** (`met1`, `met2` if needed) for `VDD`, `VSS`, input, and output pin routing.
8. Assemble and verify the complete standard cell.

**What to check:**
```bash
# Run DRC inside Magic
:drc check
:drc why
```
Confirm zero DRC violations. Then extract the SPICE netlist from the completed layout and cross-check it against the SPICE deck written in Lab 1:
```bash
:extract all
:ext2spice
ngspice extracted_inverter.spice
```
Confirm the extracted layout's simulated `Vm` and delay values reasonably match the hand-written SPICE deck's results from Lab 1 — this closes the loop between the electrical design intent and the physical layout implementation.

