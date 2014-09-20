<?php 

/* =============================================================================        

   Borja Lopez Fernandez
   
   Casale & Beach

   =============================================================================
*/
   
$currentYear         = date('Y') ;
$currentMonth        = date(m) ;
$prevMonth           = intval($currentMonth) - 1 ;
$prevMonth           = sprintf("%02s", $prevMonth) ;
$wildcard            = $currentYear . $prevMonth . "*_*.txt" ;

foreach (glob($wildcard) as $filename) {
   echo "$filename size " . filesize($filename) . "\n" ;
   unlink($filename) ;
}
  
?>
 
