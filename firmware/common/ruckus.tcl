# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load the Core
loadRuckusTcl "$::DIR_PATH/core"
loadRuckusTcl "$::DIR_PATH/VivadoHls"

# Get the family type
set family [getFpgaFamily]

if { ${family} == "kintexu" } {
    loadRuckusTcl "$::DIR_PATH/UltraScale"
}

if { ${family} eq {kintexuplus} } {
    loadRuckusTcl "$::DIR_PATH/UltraScale"
}
