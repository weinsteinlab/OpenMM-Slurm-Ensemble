set sel1 [atomselect top "protein and resid 60 and name NE"]
set sel2 [atomselect top "protein and resid 335 and name CG CD1 CD2 CE1 CE2 CZ"]
set nf [molinfo top get numframes]
set outfile [open "r60_y335.txt" "w"]
for {set i 0} {$i < $nf} {incr i} {
    $sel1 frame $i
    $sel2 frame $i
    set com1 [measure center $sel1 weight mass]
    set com2 [measure center $sel2 weight mass]
    set simdata($i.r) [veclength [vecsub $com1 $com2]]
    puts $outfile "$simdata($i.r)"
}

close $outfile

