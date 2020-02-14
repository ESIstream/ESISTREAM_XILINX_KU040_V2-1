###############################################################################
# User Configuration
###############################################################################



###############################################################################
# Timings
###############################################################################
create_clock -period 5.000 -name clk_usr_0 -waveform {0.000 2.500} [get_ports clk_xcvr_fmc_p]

###############################################################################
# IOs constraints
###############################################################################

set_property IOSTANDARD LVDS [get_ports clk_125mhz_p]
set_property PACKAGE_PIN G10 [get_ports clk_125mhz_p]
set_property PACKAGE_PIN F10 [get_ports clk_125mhz_n]

set_property PACKAGE_PIN M5 [get_ports clk_xcvr_fmc_n]
set_property PACKAGE_PIN M6 [get_ports clk_xcvr_fmc_p]


set_property PACKAGE_PIN M2 [get_ports {fmc_xcvr_in_p[0]}]
set_property PACKAGE_PIN M1 [get_ports {fmc_xcvr_in_n[0]}]
set_property PACKAGE_PIN N4 [get_ports {fmc_xcvr_out_p[0]}]
set_property PACKAGE_PIN N3 [get_ports {fmc_xcvr_out_n[0]}]
set_property PACKAGE_PIN K2 [get_ports {fmc_xcvr_in_p[1]}]
set_property PACKAGE_PIN K1 [get_ports {fmc_xcvr_in_n[1]}]
set_property PACKAGE_PIN L4 [get_ports {fmc_xcvr_out_p[1]}]
set_property PACKAGE_PIN L3 [get_ports {fmc_xcvr_out_n[1]}]
set_property PACKAGE_PIN H2 [get_ports {fmc_xcvr_in_p[2]}]
set_property PACKAGE_PIN H1 [get_ports {fmc_xcvr_in_n[2]}]
set_property PACKAGE_PIN J4 [get_ports {fmc_xcvr_out_p[2]}]
set_property PACKAGE_PIN J3 [get_ports {fmc_xcvr_out_n[2]}]
set_property PACKAGE_PIN F2 [get_ports {fmc_xcvr_in_p[3]}]
set_property PACKAGE_PIN F1 [get_ports {fmc_xcvr_in_n[3]}]
set_property PACKAGE_PIN G4 [get_ports {fmc_xcvr_out_p[3]}]
set_property PACKAGE_PIN G3 [get_ports {fmc_xcvr_out_n[3]}]

set_property IOSTANDARD LVCMOS18 [get_ports {led_usr[*]}]
set_property PACKAGE_PIN AP8 [get_ports {led_usr[0]}]
set_property PACKAGE_PIN H23 [get_ports {led_usr[1]}]
set_property PACKAGE_PIN P20 [get_ports {led_usr[2]}]
set_property PACKAGE_PIN P21 [get_ports {led_usr[3]}]
set_property PACKAGE_PIN N22 [get_ports {led_usr[4]}]
set_property PACKAGE_PIN M22 [get_ports {led_usr[5]}]
set_property PACKAGE_PIN R23 [get_ports {led_usr[6]}]
set_property PACKAGE_PIN P23 [get_ports {led_usr[7]}]

#set_property IOSTANDARD LVCMOS18 [get_ports {bp[*]}]
#set_property PACKAGE_PIN AE10 [get_ports {bp[1]}]
#set_property PACKAGE_PIN AD10 [get_ports {bp[2]}]
#set_property PACKAGE_PIN AE8 [get_ports {bp[3]}]
#set_property PACKAGE_PIN AF8 [get_ports {bp[4]}]
#set_property PACKAGE_PIN AF9 [get_ports {bp[5]}]

set_property IOSTANDARD LVCMOS18 [get_ports SW_C]
set_property IOSTANDARD LVCMOS18 [get_ports SW_N]
set_property IOSTANDARD LVCMOS18 [get_ports SW_E]
set_property IOSTANDARD LVCMOS18 [get_ports SW_S]
set_property IOSTANDARD LVCMOS18 [get_ports SW_W]
set_property PACKAGE_PIN AE10 [get_ports SW_C]
set_property PACKAGE_PIN AD10 [get_ports SW_N]
set_property PACKAGE_PIN AE8 [get_ports SW_E]
set_property PACKAGE_PIN AF8 [get_ports SW_S]
set_property PACKAGE_PIN AF9 [get_ports SW_W]

set_property IOSTANDARD LVCMOS12 [get_ports {dipswitch[*]}]
set_property PACKAGE_PIN AN16 [get_ports {dipswitch[1]}]
set_property PACKAGE_PIN AN19 [get_ports {dipswitch[2]}]
set_property PACKAGE_PIN AP18 [get_ports {dipswitch[3]}]
set_property PACKAGE_PIN AN14 [get_ports {dipswitch[4]}]

create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
create_debug_core u_ila_1 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
connect_debug_port u_ila_0/clk [get_nets [list {rx_tx_xcvr_wrapper_i/gth_tx_sfp_1/inst/gen_gtwizard_gthe3_top.gth_rx_tx_sfp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gtwiz_userclk_rx_usrclk2_out[0]} ]]
connect_debug_port u_ila_1/clk [get_nets [list {rx_tx_xcvr_wrapper_i/gth_tx_sfp_1/inst/gen_gtwizard_gthe3_top.gth_rx_tx_sfp_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gtwiz_userclk_tx_usrclk2_out[0]} ]]
set_property port_width 14 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {data_out[0][1][0]} {data_out[0][1][1]} {data_out[0][1][2]} {data_out[0][1][3]} {data_out[0][1][4]} {data_out[0][1][5]} {data_out[0][1][6]} {data_out[0][1][7]} {data_out[0][1][8]} {data_out[0][1][9]} {data_out[0][1][10]} {data_out[0][1][11]} {data_out[0][1][12]} {data_out[0][1][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {data_out[1][1][0]} {data_out[1][1][1]} {data_out[1][1][2]} {data_out[1][1][3]} {data_out[1][1][4]} {data_out[1][1][5]} {data_out[1][1][6]} {data_out[1][1][7]} {data_out[1][1][8]} {data_out[1][1][9]} {data_out[1][1][10]} {data_out[1][1][11]} {data_out[1][1][12]} {data_out[1][1][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe2]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {data_out[1][3][0]} {data_out[1][3][1]} {data_out[1][3][2]} {data_out[1][3][3]} {data_out[1][3][4]} {data_out[1][3][5]} {data_out[1][3][6]} {data_out[1][3][7]} {data_out[1][3][8]} {data_out[1][3][9]} {data_out[1][3][10]} {data_out[1][3][11]} {data_out[1][3][12]} {data_out[1][3][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe3]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {data_out[2][0][0]} {data_out[2][0][1]} {data_out[2][0][2]} {data_out[2][0][3]} {data_out[2][0][4]} {data_out[2][0][5]} {data_out[2][0][6]} {data_out[2][0][7]} {data_out[2][0][8]} {data_out[2][0][9]} {data_out[2][0][10]} {data_out[2][0][11]} {data_out[2][0][12]} {data_out[2][0][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe4]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {data_out[2][3][0]} {data_out[2][3][1]} {data_out[2][3][2]} {data_out[2][3][3]} {data_out[2][3][4]} {data_out[2][3][5]} {data_out[2][3][6]} {data_out[2][3][7]} {data_out[2][3][8]} {data_out[2][3][9]} {data_out[2][3][10]} {data_out[2][3][11]} {data_out[2][3][12]} {data_out[2][3][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe5]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {data_out[3][1][0]} {data_out[3][1][1]} {data_out[3][1][2]} {data_out[3][1][3]} {data_out[3][1][4]} {data_out[3][1][5]} {data_out[3][1][6]} {data_out[3][1][7]} {data_out[3][1][8]} {data_out[3][1][9]} {data_out[3][1][10]} {data_out[3][1][11]} {data_out[3][1][12]} {data_out[3][1][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe6]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {data_out[1][0][0]} {data_out[1][0][1]} {data_out[1][0][2]} {data_out[1][0][3]} {data_out[1][0][4]} {data_out[1][0][5]} {data_out[1][0][6]} {data_out[1][0][7]} {data_out[1][0][8]} {data_out[1][0][9]} {data_out[1][0][10]} {data_out[1][0][11]} {data_out[1][0][12]} {data_out[1][0][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe7]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list {data_out[2][2][0]} {data_out[2][2][1]} {data_out[2][2][2]} {data_out[2][2][3]} {data_out[2][2][4]} {data_out[2][2][5]} {data_out[2][2][6]} {data_out[2][2][7]} {data_out[2][2][8]} {data_out[2][2][9]} {data_out[2][2][10]} {data_out[2][2][11]} {data_out[2][2][12]} {data_out[2][2][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe8]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list {data_out[2][1][0]} {data_out[2][1][1]} {data_out[2][1][2]} {data_out[2][1][3]} {data_out[2][1][4]} {data_out[2][1][5]} {data_out[2][1][6]} {data_out[2][1][7]} {data_out[2][1][8]} {data_out[2][1][9]} {data_out[2][1][10]} {data_out[2][1][11]} {data_out[2][1][12]} {data_out[2][1][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe9]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list {data_out[0][0][0]} {data_out[0][0][1]} {data_out[0][0][2]} {data_out[0][0][3]} {data_out[0][0][4]} {data_out[0][0][5]} {data_out[0][0][6]} {data_out[0][0][7]} {data_out[0][0][8]} {data_out[0][0][9]} {data_out[0][0][10]} {data_out[0][0][11]} {data_out[0][0][12]} {data_out[0][0][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe10]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list {data_out[0][3][0]} {data_out[0][3][1]} {data_out[0][3][2]} {data_out[0][3][3]} {data_out[0][3][4]} {data_out[0][3][5]} {data_out[0][3][6]} {data_out[0][3][7]} {data_out[0][3][8]} {data_out[0][3][9]} {data_out[0][3][10]} {data_out[0][3][11]} {data_out[0][3][12]} {data_out[0][3][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe11]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe11]
connect_debug_port u_ila_0/probe11 [get_nets [list {data_out[3][0][0]} {data_out[3][0][1]} {data_out[3][0][2]} {data_out[3][0][3]} {data_out[3][0][4]} {data_out[3][0][5]} {data_out[3][0][6]} {data_out[3][0][7]} {data_out[3][0][8]} {data_out[3][0][9]} {data_out[3][0][10]} {data_out[3][0][11]} {data_out[3][0][12]} {data_out[3][0][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe12]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe12]
connect_debug_port u_ila_0/probe12 [get_nets [list {data_out[3][3][0]} {data_out[3][3][1]} {data_out[3][3][2]} {data_out[3][3][3]} {data_out[3][3][4]} {data_out[3][3][5]} {data_out[3][3][6]} {data_out[3][3][7]} {data_out[3][3][8]} {data_out[3][3][9]} {data_out[3][3][10]} {data_out[3][3][11]} {data_out[3][3][12]} {data_out[3][3][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe13]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe13]
connect_debug_port u_ila_0/probe13 [get_nets [list {data_out[1][2][0]} {data_out[1][2][1]} {data_out[1][2][2]} {data_out[1][2][3]} {data_out[1][2][4]} {data_out[1][2][5]} {data_out[1][2][6]} {data_out[1][2][7]} {data_out[1][2][8]} {data_out[1][2][9]} {data_out[1][2][10]} {data_out[1][2][11]} {data_out[1][2][12]} {data_out[1][2][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe14]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe14]
connect_debug_port u_ila_0/probe14 [get_nets [list {data_out[3][2][0]} {data_out[3][2][1]} {data_out[3][2][2]} {data_out[3][2][3]} {data_out[3][2][4]} {data_out[3][2][5]} {data_out[3][2][6]} {data_out[3][2][7]} {data_out[3][2][8]} {data_out[3][2][9]} {data_out[3][2][10]} {data_out[3][2][11]} {data_out[3][2][12]} {data_out[3][2][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 14 [get_debug_ports u_ila_0/probe15]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe15]
connect_debug_port u_ila_0/probe15 [get_nets [list {data_out[0][2][0]} {data_out[0][2][1]} {data_out[0][2][2]} {data_out[0][2][3]} {data_out[0][2][4]} {data_out[0][2][5]} {data_out[0][2][6]} {data_out[0][2][7]} {data_out[0][2][8]} {data_out[0][2][9]} {data_out[0][2][10]} {data_out[0][2][11]} {data_out[0][2][12]} {data_out[0][2][13]} ]]
create_debug_port u_ila_0 probe
set_property port_width 4 [get_debug_ports u_ila_0/probe16]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe16]
connect_debug_port u_ila_0/probe16 [get_nets [list {valid_out[0]} {valid_out[1]} {valid_out[2]} {valid_out[3]} ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe17]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe17]
connect_debug_port u_ila_0/probe17 [get_nets [list ber_status ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe18]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe18]
connect_debug_port u_ila_0/probe18 [get_nets [list cb_status ]]
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe19]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe19]
connect_debug_port u_ila_0/probe19 [get_nets [list rx_lanes_ready ]]
set_property port_width 1 [get_debug_ports u_ila_1/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list prbs_en ]]
create_debug_port u_ila_1 probe
set_property port_width 1 [get_debug_ports u_ila_1/probe1]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list tx_disp_en ]]

