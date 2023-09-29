#####CLK PERIOD CAN BE ADJUSTED UP TO 20.0 IF SYNTHESIS GOES WRONG#####
# operating conditions and boundary conditions #

set cycle  6.5   ;#clock period defined by designer 

create_clock -period $cycle [get_ports  clk]


set_dont_touch_network      [get_clocks clk]
set_clock_uncertainty  0.1  [get_clocks clk]
set_fix_hold                [all_clocks]


set_input_delay  0.1      -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay 0.2    -clock clk [all_outputs]  


set_load         0.05   [all_outputs]
set_driving_cell -lib_cell INV_X1M_A9TL -no_design_rule [remove_from_collection [all_inputs] [get_ports clk]]


set_ideal_network [get_clocks clk]
set_ideal_network [get_ports rst]

set_operating_conditions -min_library sc9_cln40g_base_lvt_ss_typical_max_0p81v_m40c  -min ss_typical_max_0p81v_m40c\
						 -max_library sc9_cln40g_base_lvt_ss_typical_max_0p81v_125c -max ss_typical_max_0p81v_125c

set_wire_load_model -name Zero -library sc9_cln40g_base_lvt_ss_typical_max_0p81v_125c
   
set_max_fanout 6 [all_inputs]
