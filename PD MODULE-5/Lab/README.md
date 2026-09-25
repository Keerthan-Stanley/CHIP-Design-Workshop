### Lab: Power Distribution Network (PDN) Construction

CONTENTS
1. Lab: Steps to Build the Power Distribution Network
2. Lab: From Power Straps to Standard-Cell Power Rails

This section walks through the complete OpenROAD flow for creating a robust power distribution network — from the core ring and straps down to the standard-cell power rails that actually feed every cell.

---

#### 1. Lab: Steps to Build the Power Distribution Network

**Goal:** Create the top-level PDN (core ring + power straps) that will later connect to the standard-cell rails.

**Steps (OpenROAD / SKY130 example):**
```bash
# 1. Load the design (after floorplan & placement)
read_lef sky130_fd_sc_hd.tlef
read_lef sky130_fd_sc_hd_merged.lef
read_def floorplan.def          # or placed.def
read_liberty sky130_fd_sc_hd__tt_025C_1v80.lib

# 2. Define the power nets
add_global_connection -net VDD -pin_pattern {VPWR} -power
add_global_connection -net VSS -pin_pattern {VGND} -ground
add_global_connection -net VSS -pin_pattern {VNB}  -ground
add_global_connection -net VDD -pin_pattern {VPB}  -power

# 3. Create the core power ring
set_voltage_domain -name CORE -power VDD -ground VSS

define_pdn_grid -name core_grid -voltage_domains CORE \
                -pins {met4 met5}

add_pdn_ring -grid core_grid \
             -layers {met4 met5} \
             -widths {2.0 2.0} \
             -spacings {1.0 1.0} \
             -core_offsets {1.0 1.0 1.0 1.0}

# 4. Add horizontal and vertical power straps
add_pdn_stripe -grid core_grid \
               -layer met4 \
               -width 1.0 \
               -pitch 20.0 \
               -offset 5.0 \
               -followpins false

add_pdn_stripe -grid core_grid \
               -layer met5 \
               -width 1.0 \
               -pitch 20.0 \
               -offset 5.0 \
               -followpins false

# Continue from the previous PDN session

# 1. Enable follow-pin (standard-cell rail) generation
#    This creates the continuous met1 power rails that run through every standard-cell row
add_pdn_stripe -grid core_grid \
               -layer met1 \
               -width 0.48 \
               -followpins true          # ← critical switch

# 2. Connect the higher metal straps down to the met1 rails
#    (OpenROAD automatically drops vias from met4/met5 → met1 at regular intervals)
pdn::run

# 3. Verify connectivity
check_power_grid -net VDD
check_power_grid -net VSS

# 4. Optional: write the final DEF and inspect in GUI
write_def pdn_complete.def
# 5. Connect the straps to the ring and generate vias
pdn::run
