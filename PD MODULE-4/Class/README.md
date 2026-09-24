### Module 9 (Class): Timing Analysis, Clock Tree Synthesis & Real Clock Constraints

CONTENTS
1. Delay Tables
2. Setup Time Analysis and Clock Jitter
3. Clock Tree Synthesis
4. Setup and Hold Analysis Using Real Clock

This section builds on the abstract timing models introduced earlier and shows how real silicon timing is calculated, how the clock network is physically built, and how setup/hold checks change once an ideal clock is replaced by an actual clock tree.

---

#### 1. Delay Tables
**What it is:** Two-dimensional lookup tables stored inside Liberty (`.lib`) files that map **input transition time (slew)** and **output load capacitance** to the resulting **propagation delay** and **output transition time** of a standard cell.

**Why they exist:** Full SPICE simulation of every cell instance in a multi-million-gate design is computationally impossible. Delay tables provide a fast, pre-characterized approximation that STA tools can interpolate in milliseconds.

**Key points:**
- Axes are usually `input_net_transition` (slew) and `total_output_net_capacitance` (load).
- Values are `cell_rise` / `cell_fall` (propagation delay) and `rise_transition` / `fall_transition` (output slew).
- Linear (or bilinear) interpolation is performed when the exact slew/load pair falls between table entries.
- Different tables exist for different process-voltage-temperature (PVT) corners.

**Why this matters:** Every path delay reported by STA ultimately comes from looking up and interpolating these tables.

---

#### 2. Setup Time Analysis and Clock Jitter
**What it is:** Verification that data launched by one flip-flop arrives at the capturing flip-flop early enough to satisfy the setup requirement of the receiving flop, even in the presence of clock uncertainty (jitter + skew).

**Key concepts:**
- **Setup equation (ideal clock):**  
  `Tclk ≥ Tck→q + Tlogic + Tsetup + Tskew`
- **Clock Jitter:** Cycle-to-cycle variation in the clock period caused by PLL/DLL noise, power-supply noise, etc. It is modelled as an uncertainty that reduces the available time for data to propagate.
- **Clock Uncertainty:** The combined effect of jitter + duty-cycle distortion + PLL phase error that is subtracted from the available clock period during setup checks.
- **Setup Slack:**  
  `Slack = Required Time − Arrival Time`  
  Positive slack → timing met; negative slack → violation.

**Why this matters:** Ignoring jitter produces optimistic STA results that fail on silicon. Real designs always include a non-zero uncertainty value.

---

#### 3. Clock Tree Synthesis (CTS)
**What it is:** The physical-design stage that builds a balanced, low-skew clock distribution network from the clock source (PLL or pad) to every sequential element in the design.

**Goals of CTS:**
- Minimize **global skew** (difference in arrival time between the earliest and latest leaf pins).
- Control **insertion delay** (latency from source to leaves).
- Meet **maximum transition / capacitance** constraints on clock nets.
- Insert clock buffers / inverters in a tree (or mesh) topology while respecting blockage and power-grid constraints.

**Typical flow:**
1. Specify clock root(s) and leaf pins.
2. Set target skew, max transition, and max capacitance.
3. Run CTS engine (e.g., OpenROAD’s TritonCTS or commercial equivalent).
4. Perform post-CTS optimization (buffer sizing, useful skew, clock gating cell placement).

**Why this matters:** After CTS the clock is no longer ideal — every register now has a real, measurable arrival time that must be used for accurate setup/hold analysis.

---

#### 4. Setup and Hold Analysis Using Real Clock
**What it is:** Re-running static timing analysis after CTS so that both launch and capture clock paths include the actual clock-tree delays and skew.

**Key differences from ideal-clock analysis:**
- Launch clock path delay and capture clock path delay are no longer assumed equal.
- **Useful skew** can now be exploited (intentionally making capture clock later than launch clock to give data more time).
- Hold-time checks become far more critical because the same clock tree that helps setup can create hold violations on short paths.
- Clock reconvergence pessimism removal (CRPR) is applied to avoid double-counting common path uncertainty.

**Typical checks performed:**
- Setup (max) analysis with real clock arrival times + uncertainty.
- Hold (min) analysis with real clock arrival times.
- Report of remaining negative slack paths for further ECO fixes.

**Why this matters:** This is the final, silicon-accurate timing sign-off view before tape-out. Ideal-clock STA is only an intermediate step.
