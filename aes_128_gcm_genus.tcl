#========================
# 0. User Variables & Directories
#========================
set DESIGN_NAME "AES_GCM" ;# Ð?i thành "DES_core" n?u ch?y bài DES
file mkdir ./OUTPUT ./REPORT

#========================
# 1. Setup Paths
#========================
set_db init_lib_search_path ../LIBS/lib/max
set_db init_hdl_search_path ./RTL

#========================
# 2. Initial Settings (All High Effort)
#========================
set_db design_process_node 45
set_db design_power_effort high
set_db hdl_preserve_unused_registers false
set_db delete_unloaded_seqs true
set_db optimize_constant_0_flops true
set_db optimize_constant_1_flops true
set_db optimize_constant_latches true

set_db syn_global_effort high
set_db retime_effort_level high
set_db retime_optimize_reset true

set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort high

set_db opt_area_recovery true
set_db opt_fix_fanout_load true
set_db opt_area_recovery_setup_target_slack 0.05
set_db opt_all_end_points true
set_db opt_add_always_on_feed_through_buffers true

# Clock gating PH?I b?t tru?c khi ch?y elaborate d? Genus nh?n di?n t? RTL
set_db lp_insert_clock_gating true

#========================
# 3. Read Libraries
#========================
read_libs [list \
    ../LIBS/lib/max/fast_vdd1v2_basicCells.lib \
    ../LIBS/lib/max/pdkIO.lib \
    ../LIBS/lib/max/pllclk_slow.lib \
]

# Avoid ULVT cells (ki?m tra t?n t?i tru?c khi set d? tránh vang l?i)
set ulvt_cells [get_db lib_cells *ULVT*]
if {[llength $ulvt_cells] > 0} {
    set_db $ulvt_cells .avoid true
}

#========================
# 4. Read RTL & Elaborate
#========================
# N?u dùng filelist.f cho Verilog 2001:
# read_hdl -language v2001 -f ./filelist.f
# N?u dùng file SystemVerilog AES_GCM:
read_hdl -language sv ./RTL/aes_128_gcm_all.sv

elaborate $DESIGN_NAME
init_design

# Gán cell Clock Gating c? th? sau khi dã có design trong b? nh?
set icg_cell [get_db lib_cells */TLATNTSCAX2]
if {[llength $icg_cell] > 0} {
    set_db design:$DESIGN_NAME .lp_clock_gating_cell $icg_cell
}

write_db -all_root_attributes ./OUTPUT/${DESIGN_NAME}.elaborate.db

#========================
# 5. Read SDC
#========================
# LUU Ý: Ð?c SDC TRU?C khi ch?y update_names d? không b? l?ch tên port bus ([0] vs _0)
read_sdc ./SDC/aes_128_gcm_1500mhz.sdc

#========================
# 6. Check Design
#========================
report_timing -lint -verbose > ./REPORT/timing_lint.rpt
check_design -all > ./REPORT/check_design.rpt

#========================
# 7. Group Paths
#========================
define_cost_group -name in2reg  -design $DESIGN_NAME
define_cost_group -name reg2reg -design $DESIGN_NAME
define_cost_group -name reg2out -design $DESIGN_NAME
define_cost_group -name in2out  -design $DESIGN_NAME

set all_regs [get_cells -hier -filter "is_sequential==true"]
set data_in  [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]

path_group -from $data_in  -to $all_regs     -group in2reg  -name in2reg
path_group -from $all_regs -to $all_regs     -group reg2reg -name reg2reg
path_group -from $all_regs -to [all_outputs] -group reg2out -name reg2out
path_group -from $data_in  -to [all_outputs] -group in2out  -name in2out

#========================
# 8. Generic Synthesis
#========================
# S?A L?I: Ph?i ch?y syn_generic ? dây tru?c khi xu?t file generic!
syn_generic

write_hdl -lec > ./OUTPUT/${DESIGN_NAME}.generic.v
write_sdc > ./OUTPUT/${DESIGN_NAME}.generic.sdc
write_db -all_root_attributes ./OUTPUT/${DESIGN_NAME}.generic.db

foreach cost_group [get_db cost_groups *] {
    set base_name [get_db $cost_group .name]
    report_timing -cost_group [list $cost_group] -max_paths 100 > ./REPORT/${base_name}.generic.rpt
}

#========================
# 9. Technology Mapping
#========================
syn_map

write_hdl -lec > ./OUTPUT/${DESIGN_NAME}.map.v
# S?A L?I: B?n g?c c?a b?n ghi nh?m thành ../OUTPUT/des.map.sdc (du 1 d?u ch?m)
write_sdc > ./OUTPUT/${DESIGN_NAME}.map.sdc
write_db -all_root_attributes ./OUTPUT/${DESIGN_NAME}.map.db
write_do_lec -golden_design rtl -revised_design ./OUTPUT/${DESIGN_NAME}.map.v > ./wlec_rtl2map.do

foreach cost_group [get_db cost_groups *] {
    set base_name [get_db $cost_group .name]
    report_timing -cost_group [list $cost_group] -max_paths 100 > ./REPORT/${base_name}.map.rpt
}

#========================
# 10. Post Optimization
#========================
syn_opt
syn_opt -incremental

#========================
# 11. Update Names (Ch?y sau cùng d? tránh l?i l?ch tên SDC/Path)
#========================
update_names -map {{"[" "_"} {"]" ""}} -inst -force
update_names -map {{"[" "_"} {"]" ""}} -port_bus
update_names -map {{"[" "_"} {"]" ""}} -hport_bus

foreach cost_group [get_db cost_groups *] {
    set base_name [get_db $cost_group .name]
    report_timing -cost_group [list $cost_group] -max_paths 100 > ./REPORT/${base_name}.final.rpt
}

#========================
# 12. Final Reports & Outputs
#========================
report_timing -max_paths 100 > ./REPORT/report_timing.rpt
report_power > ./REPORT/report_power.rpt
report_area -detail > ./REPORT/report_area.rpt
report_qor > ./REPORT/report_qor.rpt

write_db -all_root_attributes ./OUTPUT/${DESIGN_NAME}.final.db
write_hdl -lec > ./OUTPUT/${DESIGN_NAME}_netlist.v
write_sdc > ./OUTPUT/${DESIGN_NAME}_sdc.sdc

# S?A L?I LOGIC LEC: Golden ph?i là b?n .map.v, Revised là b?n sau opt (_netlist.v)
write_do_lec -golden_design ./OUTPUT/${DESIGN_NAME}.map.v -revised_design ./OUTPUT/${DESIGN_NAME}_netlist.v > ./wlec_map2final.do
write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split > ./OUTPUT/${DESIGN_NAME}_delay.sdf

exit
