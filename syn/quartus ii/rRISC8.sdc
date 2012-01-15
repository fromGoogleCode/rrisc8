## Generated SDC file "rAVR.sdc"

## Copyright (C) 1991-2011 Altera Corporation
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, Altera MegaCore Function License 
## Agreement, or other applicable license agreement, including, 
## without limitation, that your use is for the sole purpose of 
## programming logic devices manufactured by Altera and sold by 
## Altera or its authorized distributors.  Please refer to the 
## applicable agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus II"
## VERSION "Version 11.0 Build 157 04/27/2011 SJ Full Version"

## DATE    "Sat Nov 05 19:29:09 2011"

##
## DEVICE  "EP4CE22F17C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {altera_reserved_tck} -period 100.000 -waveform { 0.000 50.000 } [get_ports {altera_reserved_tck}]
create_clock -name {clk_in} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_50MHz_pad_i}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {clk} -source [get_ports {clk_50MHz_pad_i}] -duty_cycle 50.000 -multiply_by 1 -divide_by 5 -master_clock {clk_in} [get_pins {clkgen_inst|altpll_component|auto_generated|pll1|clk[0]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {altera_reserved_tck}] -rise_to [get_clocks {altera_reserved_tck}]  0.020 
set_clock_uncertainty -rise_from [get_clocks {altera_reserved_tck}] -fall_to [get_clocks {altera_reserved_tck}]  0.020 
set_clock_uncertainty -fall_from [get_clocks {altera_reserved_tck}] -rise_to [get_clocks {altera_reserved_tck}]  0.020 
set_clock_uncertainty -fall_from [get_clocks {altera_reserved_tck}] -fall_to [get_clocks {altera_reserved_tck}]  0.020 
set_clock_uncertainty -rise_from [get_clocks {clk_in}] -rise_to [get_clocks {clk_in}]  0.020 
set_clock_uncertainty -rise_from [get_clocks {clk_in}] -fall_to [get_clocks {clk_in}]  0.020 
set_clock_uncertainty -fall_from [get_clocks {clk_in}] -rise_to [get_clocks {clk_in}]  0.020 
set_clock_uncertainty -fall_from [get_clocks {clk_in}] -fall_to [get_clocks {clk_in}]  0.020 
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020 
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020 
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk}]  0.020 
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk}]  0.020 
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk_in}] -setup 0.100 
set_clock_uncertainty -rise_from [get_clocks {clk}] -rise_to [get_clocks {clk_in}] -hold 0.070 
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk_in}] -setup 0.100 
set_clock_uncertainty -rise_from [get_clocks {clk}] -fall_to [get_clocks {clk_in}] -hold 0.070 
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk_in}] -setup 0.100 
set_clock_uncertainty -fall_from [get_clocks {clk}] -rise_to [get_clocks {clk_in}] -hold 0.070 
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk_in}] -setup 0.100 
set_clock_uncertainty -fall_from [get_clocks {clk}] -fall_to [get_clocks {clk_in}] -hold 0.070 


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 
set_clock_groups -asynchronous -group [get_clocks {altera_reserved_tck}] 


#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

