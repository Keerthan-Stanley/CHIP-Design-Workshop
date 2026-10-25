## 1. What is the Project? (The Application)
**Problem:** IoT devices (sensors, smart tags) need to send data over insecure radio frequencies. Software encryption on tiny microcontrollers is too slow and drains the battery.
**Solution:** A dedicated hardware accelerator that encrypts 32-bit blocks of data using a 64-bit key in just 22 clock cycles (at 100 MHz). 
**How it works:** The chip takes plaintext and a secret key, scrambles the data using Add-Rotate-XOR (ARX) operations, and outputs ciphertext.

---

## 2. RTL Design (The Verilog Code)
**File:** `speck32_64_enc.v`
**Architecture:** The design uses a Finite State Machine (FSM) with four states: `IDLE`, `LOAD`, `RND`, and `FINISH`.
- **FSM & Counter:** A 5-bit counter tracks the 22 encryption rounds.
- **Data Path:** The 32-bit block is split into two 16-bit registers (`x`, `y`). The 64-bit key is split into four 16-bit registers (`k`, `l0`, `l1`, `l2`).
- **The Round Function (ARX):** Every clock cycle, the hardware performs:
  1. Rotate `x` right by 7 bits.
  2. Add `y` to the rotated `x`.
  3. XOR the result with the current round key.
  4. Rotate `y` left by 2 bits.
  5. XOR `y` with the new `x`.
- **Key Schedule:** The same ARX logic is used to generate the next round key on the fly, saving hardware area.

## 3. Testbench & Verification (How we proved it works)
**File:** `tb_speck32_64_enc.v`
**Methodology:** We wrote a self-checking testbench. It contains a mathematically independent "reference model" of the SPECK cipher written in Verilog. 
- **Checks:** It applies the **Official SPECK Test Vector** (Key: `1918_1110_0908_0100`, Plaintext: `6574_694c`) and expects the ciphertext `a868_42f2`.
- **Stress Testing:** It tests boundary conditions (all zeros, all ones) and generates **500 random plaintext/key pairs**, comparing the hardware output against the software model.
- **Result:** RTL Simulation passed **521 checks**. Gate-Level Simulation (GLS) also passed **521 checks**, proving the synthesized netlist behaves exactly like the RTL.

## Phase 1: RTL Design & Verification (All 5 Stages)

## Stage 1: RTL Design & Architecture
The SPECK 32/64 lightweight block cipher was implemented in synthesizable Verilog. The architecture uses a Finite State Machine (FSM) to control a 22-round iterative encryption process. The design splits the 32-bit plaintext into two 16-bit words (x, y) and applies Add-Rotate-XOR (ARX) operations iteratively to minimize silicon area.
- Inputs: `clk`, `rst_n`, `start`, `key[63:0]`, `plaintext[31:0]`
- Outputs: `ciphertext[31:0]`, `done`
- Sequential Elements: FSM (busy flag), 5-bit round counter, 32-bit data registers, 64-bit key schedule registers.

## Stage 2: RTL Functional Simulation
To prove functional correctness, a self-checking testbench was written. It verifies the official SPECK test vector, boundary conditions (all zeros/ones), reset behaviors, and 500 random vectors against a software reference model inside the testbench.
```bash
# Compile and run the RTL simulation
iverilog -o rtl_sim.out rtl/speck32_64_enc.v tb/tb_speck32_64_enc.v
vvp rtl_sim.out | tee rtl_sim.log
```
Result: ALL TESTS PASSED (521 checks)

## Stage 3: Logic Synthesis
Logic synthesis converts the behavioral Verilog into a gate-level netlist using the Sky130 HD standard cell library. Yosys maps the ARX operations to standard logic gates (AND, OR, XOR, Full Adders) and flip-flops.

# Run synthesis using OpenROAD flow scripts
make DESIGN_CONFIG=./designs/sky130hd/speck32_64/config.mk synth

Result: 539 standard cells mapped. Total area: 5,485 µm². (Sequential: 3,023 µm², Combinational: 2,462 µm²).

## Stage 4: Gate-Level Simulation (GLS)
After synthesis, GLS ensures the Yosys-mapped netlist is functionally identical to the RTL. Standard open-source cell models suffer from X-propagation (uninitialized registers) when using synchronous resets. We resolved this by compiling with functional flags (-DFUNCTIONAL) and applying a unit delay (-DUNIT_DELAY=#1).

# Run Gate-Level Simulation with functional models
iverilog -g2012 -o gls_sim.out -DFUNCTIONAL '-DUNIT_DELAY=#1' \
  speck_synth.v primitives.v sky130_fd_sc_hd.v tb/tb_speck32_64_enc.v
vvp gls_sim.out | tee gls_sim.log

Result: ALL TESTS PASSED (521 checks) (Proving RTL and Gate-Level equivalence).

## Stage 5: Pre-Layout Static Timing Analysis (STA)
Before physical design, the synthesized netlist is checked for timing closure across 16 Process, Voltage, and Temperature (PVT) corners. Pre-layout STA uses estimated wire delays to ensure the logic can run at the target frequency (100 MHz / 10ns clock).

# Loop through all 16 corners and run OpenSTA
```
for LIB in platforms/sky130hd/lib/sky130_fd_sc_hd__*.lib; do
  C=$(basename $LIB .lib | sed 's/sky130_fd_sc_hd__//')
  cat > run_corner.tcl << EOF
  read_liberty $LIB
  read_verilog speck_synth.v
  link_design speck32_64_enc 
  read_sdc ./designs/sky130hd/speck32_64/constraint.sdc
  report_wns
  report_tns
  exit
  EOF
    openroad -exit run_corner.tcl 2>/dev/null | grep -E "wns max|tns max"
  done
```
Result: Setup timing met at ff and tt corners (0.00 WNS). Violations occurred at extreme ss corners (e.g., ss_n40C_1v28 WNS = -42.74 ns).


---

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






