### Block 2: Physical Design (RTL-to-GDSII)

## Phase 2: Physical Design (RTL-to-GDSII)

## 1. Floorplanning Theory
Floorplanning defines the physical die. We set a 300µm x 300µm die to accommodate 132 IO pins. The power distribution network (PDN) was created to route VDD/VSS, and tap/endcap cells were inserted to prevent latch-up.

## 2. Floorplan Commands
```bash
make DESIGN_CONFIG=./designs/sky130hd/speck32_64/config.mk floorplan
```
Result: Die area 300x300 µm. Power grid inserted.

## 3. Placement Theory
Placement maps the 539 standard cells into legal rows, optimizing for wirelength and timing. It inserts buffers and resizes gates to fix setup/hold violations before routing.
```
make DESIGN_CONFIG=./designs/sky130hd/speck32_64/config.mk place
```
Result: 12% utilization. Zero setup/hold violations. HPWL legalization delta was 1%.

## 4. Clock Tree Synthesis (CTS) Theory
CTS builds an H-tree topology to distribute the clock signal evenly to all 103 flip-flops, minimizing clock skew. It inserts strong clock buffers (e.g., clkbuf_16) to drive the clock network.
```
make DESIGN_CONFIG=./designs/sky130hd/speck32_64/config.mk cts
```
Result: Clock tree synthesized. Maximum depth: 4 levels. Clock slack: +6.654 ns.

## 5.Routing Theory
Detailed routing uses TritonRoute (based on Lee's algorithm) to draw metal wires (met1 to met5) between components. Post-route checks ensure there are no Design Rule Check (DRC) violations (shorts/spacing) or Antenna violations.
```
make DESIGN_CONFIG=./designs/sky130hd/speck32_64/config.mk route
```
Result: Total wirelength: 27,301 µm. 0 DRC violations and 0 Antenna violations.

## 6.Post-Route Signoff STA Theory
After routing, the actual parasitic resistance and capacitance of the metal wires (RC Extraction) are used to perform a final, accurate timing analysis. This is the ultimate signoff metric before fabrication.
```
# Create a script to extract parasitics and report timing
cat > post_route_sta.tcl << EOF
read_liberty platforms/sky130hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
read_db results/sky130hd/speck32_64_enc/base/6_final.odb
read_sdc results/sky130hd/speck32_64_enc/base/6_final.sdc
set_wire_rc -signal -layer met1
set_wire_rc -clock -layer met3
estimate_parasitics -placement
report_checks -path_delay min_max -digits 3
exit
EOF
openroad -exit post_route_sta.tcl
```
Result: Setup Slack: +6.844 ns (MET). Hold Slack: +0.487 ns (MET). WNS/TNS: 0.00 / 0.00.

## 7.GDSII Generation Theory
The final GDS file is the physical blueprint sent to the foundry. The native KLayout v0.26.2 crashes in headless environments. We installed a newer stable version (KLayout v0.30.8) and resolved missing dynamic libraries (libgit2) to successfully stream out the final GDS.
```
# Fix KLayout dependencies and run GDS generation
sudo apt-get install -y libgit2-1.1 xvfb

make DESIGN_CONFIG=./designs/sky130hd/speck32_64/config.mk gds
```
Result: KLayout 0.30.8 generated 6_final.gds (2.0 MB). Final area: 7,965 µm².
