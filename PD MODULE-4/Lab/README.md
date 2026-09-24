### Module 9 (Lab): Timing Analysis, Clock Tree Synthesis & Real Clock Constraints

CONTENTS
1. Lab: Exploring Delay Tables
2. Lab: Setup Analysis with Clock Jitter / Uncertainty
3. Lab: Running Clock Tree Synthesis
4. Lab: Setup & Hold Analysis with Real Clock Network

This section walks through inspecting Liberty delay tables, applying clock uncertainty, building a real clock tree, and performing complete post-CTS setup/hold checks.

---

#### 1. Lab: Exploring Delay Tables

**Goal:** Locate and interpret a delay table inside a SKY130 Liberty file.

**Steps:**
```bash
# Open the typical-corner liberty file
less sky130_fd_sc_hd__tt_025C_1v80.lib

# Search for a specific cell (example: inv_1)
grep -A 40 'cell (sky130_fd_sc_hd__inv_1)' sky130_fd_sc_hd__tt_025C_1v80.lib

# Example SDC snippet (add to your constraints file)
create_clock -name clk -period 10 [get_ports clk]
set_clock_uncertainty -setup 0.15 [get_clocks clk]   # 150 ps jitter + margin
set_clock_uncertainty -hold  0.05 [get_clocks clk]

# Run STA (OpenSTA / OpenROAD example)
sta -exit << 'EOF'
read_liberty sky130_fd_sc_hd__tt_025C_1v80.lib
read_verilog netlist.v
link_design top
read_sdc constraints.sdc
report_checks -path_delay max -fields {slew cap input_pins}
EOF

# Inside an OpenROAD script or interactive session
read_lef sky130_fd_sc_hd.tlef
read_lef sky130_fd_sc_hd_merged.lef
read_def placed.def
read_sdc constraints.sdc

# CTS configuration
set_wire_rc -clock -layer met3
clock_tree_synthesis -buf_list "sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8" \
                     -root_buf sky130_fd_sc_hd__clkbuf_16 \
                     -sink_clustering_enable \
                     -balance_levels

# Report results
report_clock_skew
report_cts
write_def post_cts.def

# Continue from the previous OpenROAD / OpenSTA session
read_def post_cts.def
read_sdc constraints.sdc   # still contains the uncertainty values

# Setup (max) analysis
report_checks -path_delay max -format full_clock_expanded -digits 4

# Hold (min) analysis
report_checks -path_delay min -format full_clock_expanded -digits 4

# Optional: dump a detailed timing report
report_checks -path_delay max -group_count 20 > setup_report.txt
report_checks -path_delay min -group_count 20 > hold_report.txt
