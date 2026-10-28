# ============================================================
# Clock Definition
# ============================================================
set CLK_PERIOD 0.6667
set SRC_LATENCY [expr {$CLK_PERIOD * 0.05}]
set NET_LATENCY [expr {$CLK_PERIOD * 0.10}]

create_clock \
    -name clk \
    -period $CLK_PERIOD \
    -waveform [list 0 [expr {$CLK_PERIOD/2.0}]] \
    [get_ports clk]

# ============================================================
# I/O Constraints
# ============================================================
set data_inputs [remove_from_collection [all_inputs] [get_ports {clk rst_n mode}]]
set data_outputs [remove_from_collection [all_outputs] [get_ports {tag_ref_ready tag_valid verify_pass}]]

# Input/Output delay = 60% clock period
set IO_DELAY [expr {$CLK_PERIOD * 0.60}]

set_input_delay  $IO_DELAY -clock clk $data_inputs
set_output_delay $IO_DELAY -clock clk $data_outputs
set_max_delay 0.6667 \
    -from [get_ports {mode}] \
    -to [get_ports tag_ref_ready]
set_max_delay 0.6667 \
    -from [get_ports {mode}] \
    -to [get_ports tag_valid]
set_max_delay 0.6667 \
    -from [get_ports {mode}] \
    -to [get_ports verify_pass]
# ============================================================
# Reset
# ============================================================
set_case_analysis 0 [get_ports rst_n]

# ============================================================
# Don't Use Cells
# ============================================================
set_dont_use [get_lib_cells *X12*]
set_dont_use [get_lib_cells *X16*]
set_dont_use [get_lib_cells *X20*]

# ============================================================
# False Path (optional)
# ============================================================


# ============================================================
# Clock Uncertainty = 15% period
# ============================================================
set CLOCK_UNCERTAINTY [expr {$CLK_PERIOD * 0.15}]
set_clock_uncertainty $CLOCK_UNCERTAINTY [get_clocks clk]

# ============================================================
# Clock Latency = 15% period
# ============================================================
set_clock_latency -source $SRC_LATENCY [get_clocks clk]
set_clock_latency $NET_LATENCY [get_clocks clk]

# ============================================================
# DRV Constraints
# Clock transition = 10% period
# Data transition  = 20% period
# ============================================================
set CLK_MAX_TRANSITION  [expr {$CLK_PERIOD * 0.10}]
set DATA_MAX_TRANSITION [expr {$CLK_PERIOD * 0.20}]

set_max_transition $CLK_MAX_TRANSITION  [get_clocks clk]
set_max_transition $DATA_MAX_TRANSITION $data_inputs

set_max_capacitance 8f [current_design]
set_max_fanout 16 [all_outputs]

# ============================================================
# Optional Path Constraints
# Max delay = 80% period
# ============================================================
# set_max_delay [expr {$CLK_PERIOD * 0.80}] \
#     -from $data_inputs \
#     -to [all_outputs]
