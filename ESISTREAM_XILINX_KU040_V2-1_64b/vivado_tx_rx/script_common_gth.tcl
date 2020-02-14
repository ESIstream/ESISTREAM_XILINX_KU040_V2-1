# Get current path
set project_name vivado_tx_rx_common_gth
set path_file [ dict get [ info frame 0 ] file ]
set path_src [string trimright $path_file "/script_common_gth.tcl"]
#set path_project [concat $path_src/../vivado_workspace/$project_name]
set path_project C:/vw/xilinx_64b/$project_name
set path_src_rx $path_src/../src_rx
set path_src_tx $path_src/../src_tx
set path_src_co $path_src/../src_common
set path_ip_rx $path_src/../KUS/ip_rx
set path_ip_tx $path_src/../KUS/ip_tx
set path_ip_co $path_src/../KUS/ip_common
set path_sim $path_src/sim
set path_wave $path_src/wave
set path_top $path_src/top
set path_constraints $path_src/constraints
# Create project
create_project -name $project_name -dir $path_project
set_property part xcku040-ffva1156-2-E [current_project]
set_property target_language vhdl [current_project]

# Import RX IP
import_ip $path_ip_rx/output_buffer.xci
# Import common TX
import_ip $path_ip_co/clk_wiz_0.xci
import_ip $path_ip_co/gth_rx_tx_sfp.xci
import_ip $path_ip_co/add_u14.xci
import_ip $path_ip_co/sub_u14.xci

# Generate RX IP
reset_target {all} [get_ips output_buffer]
generate_target {all} [get_ips output_buffer]
# Generate common IP
reset_target {all} [get_ips clk_wiz_0]
generate_target {all} [get_ips clk_wiz_0]
reset_target {all} [get_ips gth_rx_tx_sfp]
generate_target {all} [get_ips gth_rx_tx_sfp]
generate_target {all} [get_ips add_u14]
reset_target {all} [get_ips add_u14]
generate_target {all} [get_ips sub_u14]
reset_target {all} [get_ips sub_u14]


# Add TX vhdl source files 
add_files $path_src_tx/
# Add RX vhdl source files 
add_files $path_src_rx/
# Add common vhdl source files 
add_files $path_src_co/
add_files $path_ip_co/rx_tx_xcvr_wrapper.vhd
add_files $path_top/top_esistream.vhd


# Add sim_1 source file:
add_files -fileset sim_1 $path_sim/tb_top_esistream.vhd
set_property top tb_top_esistream [get_filesets sim_1]
# Set sim_1 top level:
set_property top top_esistream [current_fileset]
# Add sim_1 wave file:
add_files -fileset sim_1 -norecurse $path_wave/tb_top_esistream_behav.wcfg
# Add constraints file
add_files -fileset constrs_1 -norecurse $path_constraints/pinout.xdc
