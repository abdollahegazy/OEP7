package require psfgen

topology /home/dboren/toppar_c36_jul21/top_all36_prot.rtf
topology /home/dboren/toppar_c36_jul21/top_all36_cgenff.rtf

mol new AF-Q9SVC4-F1-model_v4.pdb

##############3
mol new ../Alphafold/unrelaxed_model_1.pdb
set sel [atomselect top "resid > 68"]
$sel moveby [vecscale -1 [measure center $sel]]
$sel set segname P

set prot [atomselect top "protein and resid 1 to 52"]

$prot writepdb truncprot.pdb


#set $water [atomselect top "water or ions"]
#psfgen to make a segment for the protein
pdbalias residue HIS HSD

segment P {
	#pdb prot.pdb
	pdb truncprot.pdb
}
#coordpdb AF-Q8VZ95-F1-model_v4.pdb P
coordpdb truncprot.pdb P

regenerate angles dihedrals
guesscoord


#select the atoms in  vmd, write a new pdb for the truncated protein

set prot [atomselect top "protein and resid 1 to 52"]

$prot writepdb truncprot.pdb


#set $water [atomselect top "water or ions"]
#psfgen to make a segment for the protein
pdbalias residue HIS HSD

segment P {
	#pdb prot.pdb
	pdb truncprot.pdb
}
#coordpdb AF-Q8VZ95-F1-model_v4.pdb P
coordpdb truncprot.pdb P

regenerate angles dihedrals
guesscoord

writepsf OEP7.psf
writepdb OEP7.pdb


 


mol load psf OEP7.psf pdb OEP7.pdb

set OEP7 [atomselect top "protein"]

$OEP7 moveby [vecscale -1 [measure center $OEP7]]

$OEP7 writepdb OEP7_rot1.pdb

$OEP7 move [transaxis x 90]
$OEP7 writepdb OEP7_rot2.pdb

$OEP7 move [transaxis x 90]
$OEP7 writepdb OEP7_rot3.pdb

$OEP7 move [transaxis x 90]
$OEP7 writepdb OEP7_rot4.pdb

$OEP7 move [transaxis x 90]
$OEP7 move [transaxis y -90]
$OEP7 writepdb OEP7_rot5.pdb

$OEP7 move [transaxis y 180]
$OEP7 writepdb OEP7_rot6.pdb

#write out the result
package require solvate
package require autoionize
set a 115 
set c 160
set a2 [expr {$a / 2}]

#!!!There will probably be a for loop here eventually to iterate over membranes!!!
for { set memb 1 } { $memb <= 4 } { incr memb } {
	set mid [mol load psf memb-$memb/membrane.psf pdb memb-$memb/membrane.pdb]
	set memsel [atomselect $mid "not water and not segname IONS"]
	puts "STARTING MEMB-$memb"
	for { set i 1 } { $i <= 6 } { incr i } {
		mol load psf OEP7.psf pdb OEP7_rot$i.pdb
		set sel [atomselect top "all"]
		$sel moveby [list 0 0 75]
		set mid [mol fromsels [list $sel $memsel]]
		animate write psf memb-$memb/mem+prot_rot$i.psf
		animate write pdb memb-$memb/mem+prot_rot$i.pdb
		solvate memb-$memb/mem+prot_rot$i.psf memb-$memb/mem+prot_rot$i.pdb -o memb-$memb/solvated$i -minmax [list [list -$a2 -$a2 -30] [list $a2 $a2 130]]
		set keepsel [atomselect top "not (same residue as (water and abs(z)<25))"]
		$keepsel writepsf memb-$memb/solvated$i.psf
		$keepsel writepdb memb-$memb/solvated$i.pdb
		autoionize -psf memb-$memb/solvated$i.psf -pdb memb-$memb/solvated$i.pdb -cation POT -sc 0.15 -o memb-$memb/system-$i 
	}
	#ideally we would generate an xsc file here using
	#pbc get
	#pbc writexst system.xsc
	#maybe membrane specific
}



exit