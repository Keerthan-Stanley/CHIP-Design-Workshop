### Module 10 (Class): Detailed Routing — Lee’s Algorithm, DRC & TritonRoute

CONTENTS
1. Introduction to Maze Routing – Lee’s Algorithm
2. Lee’s Algorithm – Conclusion
3. Design Rule Check (DRC)
4. Basics of Global and Detail Routing & Configuring TritonRoute
5. TritonRoute Feature 1 – Honors Pre-processed Route Guides
6. TritonRoute Features 2 & 3 – Inter-guide Connectivity and Intra- & Inter-layer Routing
7. TritonRoute Method to Handle Connectivity
8. Routing Topology Algorithm

This section moves from the abstract placement stage into the physical realization of interconnects. It explains the classic maze-routing algorithm that still underpins modern detailed routers, the manufacturing rules that must be obeyed (DRC), and how OpenROAD’s TritonRoute implements a production-quality detailed router on top of global-route guides.

---

#### 1. Introduction to Maze Routing – Lee’s Algorithm
**What it is:** A classic grid-based shortest-path algorithm (breadth-first search / wavefront expansion) used to find a route between two pins while avoiding obstacles.

**How it works (high level):**
- The routing surface is modelled as a uniform grid.
- From the source pin a “wave” is expanded cell by cell, labelling each reachable cell with its distance from the source.
- Expansion continues until the target pin is reached (or the wavefront dies).
- A path is then traced back from the target to the source by following decreasing labels.

**Key properties:**
- Guarantees a shortest path in terms of grid steps (if one exists).
- Naturally handles arbitrary obstacles.
- Memory- and time-intensive on large modern designs → used today mainly as a conceptual foundation or for small regions.

---

#### 2. Lee’s Algorithm – Conclusion
**Take-aways:**
- Lee’s algorithm is optimal for maze routing on a grid but scales poorly (O(N) memory and time where N is the number of grid cells).
- Modern detailed routers therefore replace pure Lee’s search with more sophisticated techniques (A*, multi-source multi-sink, rip-up-and-reroute, parallel wavefronts, etc.) while retaining the same core idea of exploring free space until a legal path is found.
- Understanding Lee’s algorithm remains essential because every subsequent improvement (including TritonRoute’s internal search) is built on the same foundation.

---

#### 3. Design Rule Check (DRC)
**What it is:** A set of geometric manufacturing constraints imposed by the foundry that every drawn shape (wires, vias, pins) must satisfy.

**Typical DRC rules enforced during routing:**
- Minimum width of metal wires
- Minimum spacing between same-layer shapes
- Via enclosure and cut size rules
- End-of-line spacing, notch rules, antenna rules, etc.

**Why it matters:** A route that is electrically correct but violates DRC cannot be fabricated. Detailed routers must therefore treat DRC as hard constraints while searching for paths.

---

#### 4. Basics of Global and Detail Routing & Configuring TritonRoute
**Global Routing:**  
Produces a coarse “guide” for each net — a sequence of GCells (global cells) that the net should travel through. It optimizes congestion and approximate wirelength but does not produce actual metal geometry.

**Detailed Routing:**  
Takes the global-route guides and produces real metal wires and vias that obey all DRC rules and exactly connect the pins.

**TritonRoute** is OpenROAD’s detailed router.  
Typical configuration points:
- Layer range (which metal layers may be used)
- Track patterns and preferred directions
- Via generation rules
- Congestion-driven rip-up-and-reroute iterations
- DRC cleanup passes

---

#### 5. TritonRoute Feature 1 – Honors Pre-processed Route Guides
TritonRoute treats the guides produced by the global router as soft constraints.  
It tries to stay inside the guides whenever possible, but is allowed to leave them when necessary to resolve DRC or congestion.  
This “guide-aware” behaviour keeps the detailed solution close to the global plan while still giving the router freedom to fix local problems.

---

#### 6. TritonRoute Features 2 & 3 – Inter-guide Connectivity and Intra- & Inter-layer Routing
- **Inter-guide connectivity:** When a net’s guide is broken into several disconnected segments, TritonRoute is able to stitch those segments together with legal wires and vias.
- **Intra-layer routing:** Searching for paths that stay on a single metal layer (preferred for short connections).
- **Inter-layer routing:** Inserting vias to move a net between layers when required by pin access, congestion, or track availability.

These capabilities let TritonRoute finish nets whose global guides are incomplete or fragmented.

---

#### 7. TritonRoute Method to Handle Connectivity
TritonRoute models the problem as a multi-terminal, multi-layer Steiner-tree-like search under DRC constraints.  
It uses:
- A three-dimensional routing graph (x, y, layer)
- Access-point generation for pins
- Sequential or concurrent net routing with rip-up-and-reroute
- Topology optimisation to reduce vias and jogs while preserving connectivity

The goal is a fully connected, DRC-clean netlist of wires and vias.

---

#### 8. Routing Topology Algorithm
Modern detailed routers (including TritonRoute) employ topology-generation algorithms that decide the overall shape of a net before (or while) performing the detailed path search.  
Typical techniques include:
- Rectilinear Steiner minimal tree (RSMT) construction
- Pattern routing (L-shapes, Z-shapes, etc.) for two-pin nets
- Incremental topology refinement during rip-up-and-reroute

The chosen topology becomes the skeleton that the maze-search or track-assignment engine then realises with legal geometry.|

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

# 5. Connect the straps to the ring and generate vias
pdn::run

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
