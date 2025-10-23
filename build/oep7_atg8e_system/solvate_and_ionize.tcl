####
### this takes oep7+membrane system and atg8e and combines then and solvates and ionizes
####
package require topotools 1.9
package require pbctools
package require autoionize
package require solvate

# load membrane+oep7 pdb/psf and atg8e pdb/psf
set ProtSys [mol load psf /dogwood/tank/Duncan/OEP7/Build/structures/atg8e/atg8e.psf pdb /dogwood/tank/Duncan/OEP7/Build/structures/atg8e/atg8e.pdb]
set MemSys [mol load psf /dogwood/tank/Duncan/OEP7/Build/integral/memb-1p.psf pdb /dogwood/tank/Duncan/OEP7/Build/integral/memb-1p.pdb]

# select all but water and ions from memsys
set mem [atomselect $MemSys "all not (water or ions)"]
# make sure select only protein 
set prot [atomselect $ProtSys "protein"]

# move the atg8e protein higher and to the side (this was done by visual inspection)
$prot moveby {0 15 100}

#combine using topotools
set combined [::TopoTools::selections2mol [list $prot $mem]]
animate write psf oep7_atg8e.psf $combined
animate write pdb oep7_atg8e.pdb $combined

#load for solvation
set system_pdb oep7_atg8e.pdb
set system_psf oep7_atg8e.psf

# box system (calculated from vmd and then made x/y a little smaller cuz safer)
solvate $system_psf $system_pdb \
    -o ./solvated/system \
    -minmax [list [list -67.5 -67.5 -60] [list 67.5 67.5 110]]

# remove waters on membrane (same as duncan in his oep7 script but i did 20 instead of 25, 25 caused a slight layer of no water above membrane)
set keepsel [atomselect top "not (same residue as (water and abs(z)<20))"]
$keepsel writepdb ./solvated/system.pdb
$keepsel writepsf ./solvated/system.psf

#solvate and ionize
set solvated_pdb ./solvated/system.pdb
set solvated_psf ./solvated/system.psf


autoionize -psf $solvated_psf -pdb $solvated_pdb -cation POT -sc 0.15 -o ./ionized/system

# write box size
mol load psf ./ionized/system.psf pdb ./ionized/system.pdb
pbc writexst ./ionized/system.xsc

#delete unneeded file and quit
file delete -force oep7_atg8e.pdb oep7_atg8e.psf

quit