# package require topotools 1.9
package require pbctools
package require autoionize
package require solvate

set ProtSys [mol load psf /dogwood/tank/Duncan/OEP7/Build/structures/atg8e/atg8e.psf pdb /dogwood/tank/Duncan/OEP7/Build/structures/atg8e/atg8e.pdb]
set MemSys [mol load psf /dogwood/tank/Duncan/OEP7/Build/integral/memb-1p.psf pdb /dogwood/tank/Duncan/OEP7/Build/integral/memb-1p.pdb]

###Move protein to (0 0 ????) over membrane
set mem [atomselect $MemSys "all not (water or ions)"]
set prot [atomselect $ProtSys "protein"]

# $prot moveby [vecscale -1 [measure center $prot]]
$prot moveby {0 15 100}

set combined [::TopoTools::selections2mol [list $prot $mem]]
animate write psf oep7_atg8e.psf $combined
animate write pdb oep7_atg8e.pdb $combined


set system_pdb oep7_atg8e.pdb
set system_psf oep7_atg8e.psf

package require solvate
package require autoionize

# set a 161.2289962 
set a 140
# set c 100.406998
set a2 [expr {$a / 2}]

#for vap27-1, our dimensions are
#{-82.46099853515625 -78.20600128173828 -28.957000732421875} {78.76799774169922 85.74600219726562 81.80899810791016}
#161.2289962 x 163.9520035 x 110.7659988

solvate $system_psf $system_pdb \
    -o ./solvated/system \
    -minmax [list [list -67.5 -67.5 -60] [list 67.5 67.5 110]]

set keepsel [atomselect top "not (same residue as (water and abs(z)<20))"]
$keepsel writepdb ./solvated/system.pdb
$keepsel writepsf ./solvated/system.psf

set solvated_pdb ./solvated/system.pdb
set solvated_psf ./solvated/system.psf


autoionize -psf $solvated_psf -pdb $solvated_pdb -cation POT -sc 0.15 -o ./ionized/system

mol load psf ./ionized/system.psf pdb ./ionized/system.pdb


pbc writexst ./ionized/system.xsc

quit