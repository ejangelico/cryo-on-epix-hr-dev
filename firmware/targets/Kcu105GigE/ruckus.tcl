# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Check for version 2016.4 of Vivado
if { [VersionCheck 2016.4] < 0 } {
    close_project
    exit -1
}

# Load submodules' code and constraints
loadRuckusTcl $::env(TOP_DIR)/submodules

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/hdl/"

if { "$::env(USE_RJ45_ETH)" != 0 } {
   loadConstraints -path "$::DIR_PATH/hdl/Kcu105GigE_Sgmii.xdc"
} else {
   loadConstraints -path "$::DIR_PATH/hdl/Kcu105GigE_Gth.xdc"
}
loadConstraints -path "$::DIR_PATH/hdl/Kcu105GigE.xdc"


set_property top {RssiCoreTb} [get_filesets sim_1]
