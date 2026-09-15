# Create a local project structure in memory
create_project -in_memory -part xc7a35tcsg324-1

# Read all design files
read_verilog -sv [glob ../interface/*.sv]
read_verilog -sv [glob ../source/*.sv]
read_verilog -sv [glob ../testbench/pll_test.sv]

# Elibrate and run the simulation using Vivado's native engine flow
launch_simulation -type behavioral -simset sim_1
run all