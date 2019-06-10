set num_frames [molinfo top get numframes]
set output [open "na2_water_coord.txt" "w"]
set selection [atomselect top "noh and water within 3.1 of resname SOD and resid 622" ]
for {set i 0} {$i < $num_frames} {incr i} {
   $selection frame $i
   $selection update 
   set num [$selection num]
   puts $output $num
 }
close $output

