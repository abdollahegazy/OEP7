#default probe from freesasa = 1.4
#HEAVILY INSPIRED FROM https://www.ks.uiuc.edu/Research/vmd/mailing_list/vmd-l/att-18670/sasa.tcl 

set load_every 10

mol new system.psf

set dcd_files [lsort [glob -nocomplain system_run*.dcd]]
set num_dcds [llength $dcd_files]

puts "Found $num_dcds DCD files"

#load trajs
foreach dcd_file $dcd_files {
    mol addfile $dcd_file step $load_every waitfor all
}

# calculate and print SASA for LGWLAI motif
set nframes [molinfo top get numframes]

#select membrane as well, NOT just protein
set system [atomselect top "not (water or ions)"]

for {set frame 0} {$frame < $nframes} {incr frame} {
    #update system for new frame
    $system frame $frame

    #verified to be resid 19 to 24
    set motif [atomselect top "protein and resid 19 to 24" frame $frame] 
    set sasa [measure sasa 1.4 $system -restrict $motif]
    puts "Frame $frame: SASA = $sasa "

    #just deleting to be safe 
    $motif delete
}

puts "Done (VMD)"
quit