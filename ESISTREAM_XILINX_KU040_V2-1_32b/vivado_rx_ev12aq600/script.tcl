# Get current path
set project_name vivado_rx_aq600
set path_file [ dict get [ info frame 0 ] file ]
set path_src [string trimright $path_file "/script.tcl"]
#set path_project [concat $path_src/../vivado_workspace/$project_name]
set path_project C:/vw/xilinx_32b/$project_name
set path_src_rx $path_src/../src_rx
set path_src_co $path_src/../src_common
set path_ip_rx $path_src/../KUS/ip_rx
set path_ip_rx_custom $path_src/ip_rx
set path_ip_co $path_src/../KUS/ip_common
set path_src_ramp_test $path_src/src_ramp_test
set path_wave $path_src/wave
set path_top $path_src/top
set path_xdc $path_src/xdc
# Create project
create_project -name $project_name -dir $path_project
set_property part xcku040-ffva1156-2-E [current_project]
set_property target_language vhdl [current_project]

# Import RX IP
import_ip $path_ip_rx/output_buffer.xci
# Import common TX
import_ip $path_ip_rx_custom/clk_wiz_0.xci
import_ip $path_ip_rx_custom/gth_rx_tx_sfp.xci
import_ip $path_ip_rx_custom/add_u12.xci
import_ip $path_ip_rx_custom/sub_u12.xci

# Generate RX IP
reset_target {all} [get_ips output_buffer]
generate_target {all} [get_ips output_buffer]
# Generate common IP
reset_target {all} [get_ips clk_wiz_0]
generate_target {all} [get_ips clk_wiz_0]
reset_target {all} [get_ips gth_rx_tx_sfp]
generate_target {all} [get_ips gth_rx_tx_sfp]
reset_target {all} [get_ips add_u12]
generate_target {all} [get_ips add_u12]
reset_target {all} [get_ips sub_u12]
generate_target {all} [get_ips sub_u12]

# Add RX vhdl source files 
add_files $path_src_rx/
add_files $path_ip_rx_custom/rx_xcvr_wrapper.vhd
add_files $path_src_ramp_test/timer.vhd
add_files $path_src_ramp_test/risingedge.vhd
add_files $path_src_ramp_test/spi_refclk.vhd
add_files $path_src_ramp_test/sync_generator.vhd
add_files $path_src_ramp_test/spi_dual_master.vhd
add_files $path_src_ramp_test/spi_dual_master_fsm_6400M.vhd
add_files $path_src_ramp_test/aq600_interface.vhd

# Add common vhdl source files 
add_files $path_src_co/
add_files $path_top/rx_check_aq600.vhd
add_files $path_top/rx_esistream_top.vhd
set_property top rx_esistream_top [current_fileset]

# Add xdc source file
add_files -fileset constrs_1 $path_xdc/rx_esistream_top.xdc
