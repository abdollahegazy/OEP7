package require psfgen
package require pbctools

set sim_dir "../../simulations/oep7_atg8e_system/integral/memb-1/harmonic_restraint/"
set dcd_file "${sim_dir}/system_pull004.dcd"

mol new "${sim_dir}/system.psf"
mol addfile "${sim_dir}/system.pdb" waitfor all
mol addfile $dcd_file waitfor all step 1

set molid [molinfo top]
set lastframe [molinfo $molid get numframes]
incr lastframe -1

set system [atomselect top all frame $lastframe]

$system writepdb "${sim_dir}/final_system.pdb"

# animate write pdb "${sim_dir}/final_system.pdb" beg $lastframe end $lastframe mol $system
# writepsf "${sim_dir}/final_system.psf"

# Write final XSC (box vectors and origin) 
set a [molinfo $molid get a]
set b [molinfo $molid get b]
set c [molinfo $molid get c]
set o [molinfo $molid get {center}]

set xsc [open "${sim_dir}/final_system.xsc" w]
puts $xsc "# NAMD extended system"
puts $xsc "#\$LABELS step a_x a_y a_z b_x b_y b_z c_x c_y c_z o_x o_y o_z"
puts $xsc "0 $a 0 0 0 $b 0 0 0 $c [lindex $o 0] [lindex $o 1] [lindex $o 2]"
close $xsc

# --- Done ---
puts "Wrote final_system.{pdb, psf, xsc} to $sim_dir"

exit