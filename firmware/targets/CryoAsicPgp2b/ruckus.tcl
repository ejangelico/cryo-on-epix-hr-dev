############################
# DO NOT EDIT THE CODE BELOW
############################

# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules

# Load target's source code and constraints
loadSource      -dir  "$::DIR_PATH/hdl/"
loadConstraints -dir  "$::DIR_PATH/hdl/"

# Adding the common Si5345 configuration
add_files -norecurse "$::DIR_PATH/../../../software/config/Si5345-RevD-Regmap-56MHz.mem"
