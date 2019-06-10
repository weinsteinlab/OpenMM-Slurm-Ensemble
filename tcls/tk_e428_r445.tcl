set sel1 [atomselect top "protein and resid 428 and name CD"]
set sel2 [atomselect top "protein and resid 445 and name CZ"]
set nf [molinfo top get numframes]
set outfile [open "e428_r445.txt" "w"]
for {set i 0} {$i < $nf} {incr i} {
    $sel1 frame $i
    $sel2 frame $i
    set com1 [measure center $sel1 weight mass]
    set com2 [measure center $sel2 weight mass]
    set simdata($i.r) [veclength [vecsub $com1 $com2]]
    puts $outfile "$simdata($i.r)"
}

close $outfile

