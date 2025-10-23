proc rotatebond {idxlist idx idx2 rot {mid top} {f now}} {
	#idxlist is the list of indices that will get rotated. idx is bonded to an element in idxlist, and that is the bond around which we will be rotating.
	set rotatesel [atomselect $mid "index $idxlist" frame $f]
	set basesel [atomselect $mid "index $idx"]
	set partner [atomselect $mid "index $idx2"]
	if {[$basesel num] != 1} {
		puts "Second argument results in a atomselection of the wrong size."
		puts "Atomselection size: [$basesel num]"
		return
	}
	if {[$partner num] != 1} {
		puts "Third argument results in a atomselection of the wrong size."
		puts "Atomselection size: [$parter num]"
		return
	}
	set M [trans bond  [lindex [$basesel get {x y z}] 0] [lindex [$partner get {x y z}] 0] $rot deg]
	$rotatesel move $M
	$partner delete
	$rotatesel delete
	$basesel delete
}
#------------------------------------------------------------------------------
#Split a bond, and see which side is bigger. We'll be moving the smaller of the two sides.
proc selectsmaller { idx1 idx2 {mid top} } {
	set sel1 [atomselect $mid "index $idx1"]
	set sel2 [atomselect $mid "index $idx2"]
	#Expand the tree.
	set newsel1 [atomselect $mid "index $idx1 [join [$sel1 getbonds]] and not index $idx2"]
	set nidx1 [$newsel1 get index]
	set newsel2 [atomselect $mid "index $idx2 [join [$sel2 getbonds]] and not index $nidx1"]
	if { [$sel1 num] == [$newsel1 num] || [$sel2 num] == [$newsel2 num]} {
		puts "Bond not rotateable"
		return
	}
	#Keep expanding the selections until we are out of stuff to expand to on one side.
	while { [$sel1 num] != [$newsel1 num] && [$sel2 num] != [$newsel2 num] } {
		$sel1 delete
		$sel2 delete
		set sel1 $newsel1
		set sel2 $newsel2
		set nidx2 [$newsel2 get index]
		set newsel1 [atomselect $mid "index $nidx1 [join [$sel1 getbonds]] and not index $nidx2"]
		set nidx1 [$newsel1 get index]
		set newsel2 [atomselect $mid "index $nidx2 [join [$sel2 getbonds]] and not index $nidx1"]
	}
	set nidx2 [$newsel2 get index]
	if { [$sel1 num] == [$newsel1 num] } {
		set retval [list $idx2 $idx1 $nidx1]
	} else {
		set retval [list $idx1 $idx2 $nidx2]
	}
	#Cleanup.
	$sel1 delete
	$sel2 delete
	$newsel1 delete
	$newsel2 delete
	return $retval
}
#------------------------------------------------------------------------------
#This is the guy that rotates a bond based on two indices.
proc autorotatebond {idx1 idx2 rot {mid top} {f now}} {
	#Designed to be the "lazy" way of rotating a bond. Just give it two bonded atoms and a rotation, and it'll figure out the rest!
	lassign [selectsmaller $idx1 $idx2 $mid] idx i ilist
	rotatebond $ilist $idx $i $rot $mid $f
}

package require pbctools
package require psfgen

topology /fir/tank/abdolla/docking/dock_comp/vina_boltz/toppar/top_all36_lipid.rtf
topology /fir/tank/abdolla/docking/dock_comp/vina_boltz/toppar/top_all36_cgenff.rtf
topology /dogwood/tank/Duncan/OEP7/Build/memPatches.top

#C
##! Add 1..4 for loop
# 
for { set m 1 } { $m <= 1 } { incr m } {
	readpsf "ionized/system.psf" pdb "ionized/system.pdb"
	
	#pdbalias atom DOPC XYZ XY
	
	mol load psf "ionized/system.psf" pdb "ionized/system.pdb"
	
	set sel [atomselect top "resname DOPC and name P"]

	set residuelist [$sel get resid]
	
	foreach resid $residuelist {
	    patch P1 MEMB:$resid
	}

	set sel [atomselect top "resname POPG and name P"]
	set residuelist [$sel get resid]
	
	foreach resid $residuelist {
	    patch P2 MEMB:$resid
	}
	
	regenerate angles dihedrals
	
	guesscoord
	
	writepdb "patched/system.pdb"
	writepsf "patched/system.psf"
	
	mol load psf "patched/system.psf" pdb "patched/system.pdb"
	
	#fixing up our DOPC dihedrals
	set transsel [atomselect top "resname DOPC and name C215 C216 C212 C213"]
	set idxlist [$transsel get index]
	
	for { set i 0 } { $i < [llength $idxlist] } { incr i 2 } {
		set j [expr {$i + 1}]
		set newsel1 [atomselect top "noh and withinbonds 1 of index [lindex $idxlist $i] [lindex $idxlist $j]"]
		puts [$newsel1 get index]
		set rotateBy [measure dihed [$newsel1 get index]]
		set rotateBy [expr {-1 * $rotateBy}]
		autorotatebond [lindex $idxlist $i] [lindex $idxlist $j] $rotateBy
	}
	
	
	#fixing up our POPG dihedrals
	
	set transsel [atomselect top "resname POPG and name C215 C216 C212 C213"]
	set idxlist [$transsel get index]
	
	for { set i 0 } { $i < [llength $idxlist] } { incr i 2 } {
		set j [expr {$i + 1}]
		set newsel1 [atomselect top "noh and withinbonds 1 of index [lindex $idxlist $i] [lindex $idxlist $j]"]
		puts [$newsel1 get index]
		set rotateBy [measure dihed [$newsel1 get index]]
		set rotateBy [expr {-1 * $rotateBy}]
		autorotatebond [lindex $idxlist $i] [lindex $idxlist $j] $rotateBy
	}
	
	#now we need to do this for the 3t-16, on atoms C32 abd C33
	#resname POPG and resid 153 and type CEL1
	set transsel [atomselect top "resname POPG and name C32 C33"]
	set idxlist [$transsel get index]
	
	for { set i 0 } { $i < [llength $idxlist] } { incr i 2 } {
		set j [expr {$i + 1}]
		set newsel1 [atomselect top "noh and withinbonds 1 of index [lindex $idxlist $i] [lindex $idxlist $j]"]
		puts [$newsel1 get index]
		set rotateBy [measure dihed [$newsel1 get index]]
		set rotateBy [expr {-1 * $rotateBy}]
		autorotatebond [lindex $idxlist $i] [lindex $idxlist $j] $rotateBy
	}
	
	set savesel [atomselect top "all"]
	$savesel writepdb "patched/system.pdb"
    $savesel writepsf "patched/system.psf"
	resetpsf
}
quit
