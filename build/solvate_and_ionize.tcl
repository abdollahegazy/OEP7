package require psfgen
package require solvate
package require autoionize
package require pbctools

topology /fir/tank/abdolla/docking/dock_comp/vina_boltz/toppar/top_all36_prot.rtf
topology /fir/tank/abdolla/docking/dock_comp/vina_boltz/toppar/top_all36_lipid.rtf
topology /fir/tank/abdolla/docking/dock_comp/vina_boltz/toppar/top_all36_cgenff.rtf
topology /fir/tank/abdolla/docking/dock_comp/vina_boltz/toppar/top_all36_carb.rtf
topology /dogwood/tank/Duncan/OEP7/Build/memPatches.top

# topology /dogwood/tank/Duncan/OEP7/Build/integral/charmm-gui-2624744745/toppar/toppar_all36_lipid_dag.str
# topology /dogwood/tank/Duncan/OEP7/Build/peripheral/emptyMembs/charmm-gui-2503134187/membrane_restraint.str

set toppar_dir "/dogwood/tank/Duncan/OEP7/Build/peripheral/emptyMembs/charmm-gui-2503184019/toppar/"
topology /tank/abdolla/oep7/OEP7/Build/integral/charmm-gui-2624744745/toppar/toppar_all36_lipid_miscellaneous.str

topology /dogwood/tank/Duncan/OEP7/Build/peripheral/emptyMembs/charmm-gui-2503274133/toppar/toppar_all36_lipid_ether.str
foreach topo [glob ${toppar_dir}/*.str ${toppar_dir}/*.rtf] {
     catch {topology $topo} 
}


pdbalias residue HIS HSD
pdbalias atom ILE CD1 CD
pdbalias residue PILP PILPC
pdbalias residue LLPAA LLPA
pdbalias residue PLEP PLEPEp
pdbalias residue BGALG BGAL


#output everything to here
set output_dir "./solvated_and_ionized"

#load the properly oritented system from packmol
# mol new "combined_reflected.pdb" type pdb
mol new "temp_combined.pdb" type pdb

set membrane [atomselect top "not (protein or water or ions)"]
set oep7 [atomselect top "segname PROA"]
set atg8 [atomselect top "segname P"]

#select each part and write out
set temp_MEMB "${output_dir}/temp_MEMB.pdb"
set temp_PROA "${output_dir}/temp_PROA.pdb"
set temp_P "${output_dir}/temp_P.pdb"

$membrane writepdb $temp_MEMB
$oep7 writepdb $temp_PROA
$atg8 writepdb $temp_P

resetpsf
mol delete all 


#membrane had alot of duplicate residue keys so im gonna renumber them.
# not doing this caused psfgen gen to skip alot of the lipids in the membrane
# mol new $temp_MEMB
set sel [atomselect top "all"]

# rename residues sequentailly
set residues [lsort -unique -integer [$sel get residue]]
set newresid 1
foreach residue $residues {
    set ressel [atomselect top "residue $residue"]
    $ressel set resid $newresid
    incr newresid
}

set all [atomselect top "all"]
$all writepdb "${output_dir}/temp_MEMB.pdb"

psf stuff


segment MEMB {
    pdb $temp_MEMB
}
coordpdb $temp_MEMB MEMB

segment PROA {
    pdb $temp_PROA
}
coordpdb $temp_PROA PROA

segment P {
    pdb $temp_P
}
coordpdb $temp_P P

regenerate angles dihedrals
guesscoord

# initial PSF/PDB
set initial_psf "${output_dir}/initial.psf"
set initial_pdb "${output_dir}/initial.pdb"


writepsf $initial_psf
writepdb $initial_pdb

mol delete all
quit
#load initial system w/ psf
mol load psf $initial_psf pdb $initial_pdb


#solvate. these coordinates are found from duncan's dir where he got the membrane dimensions from CHARMM
#im using very similar XY just going higher up for protein
solvate $initial_psf $initial_pdb \
    -o "${output_dir}/solvated" \
    -minmax [list [list -69.5 -69.5 -80] [list 69.5 69.5 90]]

mol delete all

mol load psf "${output_dir}/solvated.psf" pdb "${output_dir}/solvated.pdb"

# Remove waters that overlap with the membrane. follow duncan's script of removing z threshold from membrane center
set membrane [atomselect top "segname MEMB"]
set memb_minmax [measure minmax $membrane]
lassign $memb_minmax memb_min memb_max
set memb_zmin [lindex $memb_min 2]
set memb_zmax [lindex $memb_max 2]
set memb_zcenter [expr {($memb_zmin + $memb_zmax) / 2.0}]

# puts "Membrane center Z: $memb_zcenter"
$membrane delete

# remove waters where abs(z - membrane_center) < threshold
#tried doing 25 but that just removes band of water above and below membrane, this seems fine?
#maybe i can just omitt this???
set z_threshold 5

set waters_before [atomselect top "water"]
puts "Waters before cleanup: [$waters_before num] atoms"

# Keep everything EXCEPT waters near membrane center
set keepsel [atomselect top "not (same residue as (water and abs(z - $memb_zcenter) < $z_threshold))"]
# set keepsel [atomselect top "not (same residue as (water and abs(z) < $z_threshold))"]. this doesnt center at membrane i think

$keepsel writepsf "${output_dir}/solvated_clean.psf"
$keepsel writepdb "${output_dir}/solvated_clean.pdb"

mol delete all
mol load psf "${output_dir}/solvated_clean.psf" pdb "${output_dir}/solvated_clean.pdb"

set waters_after [atomselect top "water"]
puts "Waters after cleanup: [$waters_after num] atoms"
puts "Removed [expr [$waters_before num] - [$waters_after num]] water atoms from membrane core"

# # Ionize the system then done
puts "\nIonizing system (0.15 M salt)..."
autoionize \
    -psf "${output_dir}/solvated_clean.psf" \
    -pdb "${output_dir}/solvated_clean.pdb" \
    -cation POT \
    -sc 0.15 \
    -o "${output_dir}/system"

puts "Ionization complete"

# # Load final system and write XSC file
mol delete all
mol load psf "${output_dir}/system.psf" pdb "${output_dir}/system.pdb"



pbc writexst "${output_dir}/system.xsc"


file delete -force $temp_MEMB $temp_PROA $temp_P
file delete -force $initial_psf $initial_pdb
file delete -force "${output_dir}/solvated.psf" "${output_dir}/solvated.pdb"
file delete -force "${output_dir}/solvated_clean.psf" "${output_dir}/solvated_clean.pdb"
mol delete all

quit