package require pbctools
package require psfgen
package require solvate
package require autoionize

set sim_dir "../../simulations/oep7_atg8e_system/integral/memb-1/harmonic_restraint/"
set out_dir "./"
# Load the final system

mol load psf "${sim_dir}/system.psf" pdb "${sim_dir}/final_system.pdb"

pbc readxst "${sim_dir}/final_system.xsc"

set system [atomselect top all]
set prot [atomselect top "segname P"]

# Center the protein 
# $prot moveby [vecscale -1 [measure center $prot]]

# Move it up 10 angstroms in z

$prot moveby {0 0 10}
set prot_center [measure center $prot]


$system writepdb "${out_dir}/protein_rot1.pdb"


# Rotate around x-axis: 90° increments (4 faces)
# Move to origin, rotate, move back
$prot moveby [vecscale -1 $prot_center]
$prot move [transaxis x 90]
$prot moveby $prot_center
$system writepdb "${out_dir}/protein_rot2.pdb"

$prot moveby [vecscale -1 $prot_center]
$prot move [transaxis x 90]
$prot moveby $prot_center
$system  writepdb "${out_dir}/protein_rot3.pdb"

$prot moveby [vecscale -1 $prot_center]
$prot move [transaxis x 90]
$prot moveby $prot_center
$system  writepdb "${out_dir}/protein_rot4.pdb"

# Rotation 5: top face (rotate around y from original)
$prot moveby [vecscale -1 $prot_center]
$prot move [transaxis x 90]
$prot move [transaxis y -90]
$prot moveby $prot_center
$system  writepdb "${out_dir}/protein_rot5.pdb"

# Rotation 6: bottom face
$prot moveby [vecscale -1 $prot_center]
$prot move [transaxis y 180]
$prot moveby $prot_center
$system  writepdb "${out_dir}/protein_rot6.pdb"
# puts "Wrote 6 rotated protein orientations to $out_dir"

exit

# set system [mol new psf systembuild/protein.psf]
# mol addfile systembuild/protein.coor $molid_prot
# pbc readxst systembuild/protein.xsc

# set box2 [lindex [pbc get] 0]

# set prot [atomselect $molid_prot "not resname TIP3 SOD CLA"]

# $prot moveby [vecscale -1 [measure center $prot]]

# $prot writepdb protein_rot1.pdb

# $prot move [transaxis x 90]
# $prot writepdb protein_rot2.pdb

# $prot move [transaxis x 90]
# $prot writepdb protein_rot3.pdb

# $prot move [transaxis x 90]
# $prot writepdb protein_rot4.pdb

# $prot move [transaxis x 90]
# $prot move [transaxis y -90]
# $prot writepdb protein_rot5.pdb

# $prot move [transaxis y 180]
# $prot writepdb protein_rot6.pdb
#  ´
# quit
