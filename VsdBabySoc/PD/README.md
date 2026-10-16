## Physical Design (PD)

The VSDBabySoC physical design flow was completed using **OpenLane** with the **Sky130A PDK** on the Ubuntu environment. The flow takes the synthesized gate-level netlist from RTL synthesis through floorplanning, placement, clock tree synthesis, routing, and final GDS generation.

### Tools and PDK

| Item | Value |
|------|-------|
| Flow automation | OpenLane |
| PDK | Sky130A (sky130_fd_sc_hd) |
| Synthesis | Yosys + ABC |
| Floorplan | OpenROAD / init_floorplan |
| Placement | RePlAce + detailed placement |
| Clock Tree | TritonCTS |
| Routing | TritonRoute |
| RC Extraction | OpenRCX |
| Static Timing | OpenSTA |
| DRC | Magic / KLayout |
| LVS | Netgen |
| GDS Stream-out | Magic |

### PD Flow Steps

#### 1. Design Preparation

- Load gate-level netlist `vsdbabysoc.synth.v`
- Load SDC constraints `vsdbabysoc_synthesis.sdc`
- Load Sky130 liberty, LEF, and tech files
- Set target die area and core utilization in `config.tcl`

#### 2. Floorplanning

- Defined die area and core area
- Set aspect ratio to 1 (square die)
- Set core utilization target
- Placed IO pins around the die boundary
- Inserted tap cells and endcap cells
- Built the power distribution network (PDN) with VDD/VSS straps on metal layers
- Output: `vsdbabysoc.floorplan.def`

#### 3. Placement

- Global placement with RePlAce to minimize wirelength
- Detailed placement to snap cells to legal sites in standard-cell rows
- Timing-driven optimization: buffer insertion and cell resizing to fix setup/hold
- Output: `vsdbabysoc.placement.def`

#### 4. Clock Tree Synthesis (CTS)

- Built balanced clock tree with TritonCTS
- Inserted clock buffers to minimize skew
- Reduced clock latency across the design
- Output: `vsdbabysoc.cts.def`

#### 5. Routing

- Global routing to plan metal layer usage
- Detailed routing with TritonRoute (Lee's algorithm-based maze routing)
- Post-route optimization for DRC and timing closure
- Output: `vsdbabysoc.routing.def`

#### 6. RC Extraction

- Extracted parasitic resistance and capacitance from routed layout
- Generated SPEF file for accurate post-layout timing
- Output: `vsdbabysoc.spef`

#### 7. Signoff STA (Post-Layout)

- Re-ran STA with actual extracted parasitics
- Verified setup and hold at all PVT corners
- Confirmed timing closure
- Output: `vsdbabysoc_postroute_sta.rpt`

#### 8. Physical Verification

- **DRC** — Design Rule Check using Magic against Sky130 rules
- **LVS** — Layout vs Schematic using Netgen
- **Antenna check** — verified no charge buildup violations
- Output: DRC clean, LVS clean

#### 9. GDS Stream-out

- Final layout exported to GDSII format
- Ready for mask generation and fabrication
- Output: `vsdbabysoc.gds`

### OpenLane Run Command

```bash
cd ~/Desktop/work/tools/openlane_working_dir/openlane
flow.tcl -design vsdbabysoc
