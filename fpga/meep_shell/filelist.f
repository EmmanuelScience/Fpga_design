-F ../common/filelist.f
###############################################################################
#  meep_shell/filelist.f  – used by project_options.tcl and by simulators     #
###############################################################################

# Tell tools where to look for headers
+incdir+src/

# Global definitions
src/defines.svh

# RTL hierarchy
src/fifo_axi.sv
src/axi_pcie_fifo_accel.v
src/fifo_wrapper.sv

# Top that the shell itself instantiates
accelerator_mod.sv
