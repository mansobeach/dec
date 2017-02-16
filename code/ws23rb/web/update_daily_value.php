<html>
 <head>
  <title>Casale & Beach / update_daily_values.php</title>
 </head>
  
 <?php 
   
   
/* =============================================================================        

   Borja Lopez Fernandez
   
   Casale & Beach

   =============================================================================

   update_daily_value.php?station=LEON&variable=temperature-outdoor

   Interface parameters:
   - station 
   - variable

*/

   // --------------------------------------------
   //
   // get station name   
   
   $stationName         = $_GET["station"] ;
   $fileMeteo           = "METEO_" . $stationName . ".xml" ;

   // --------------------------------------------
   //
   // get variable name   

   $currentDate         = date('Ymd') ;
   $variable            = $_GET["variable"] ;
   $fileVariable        = $currentDate . "_" . $variable . ".txt" ;
   
   // --------------------------------------------
   
   
   // --------------------------------------------
   // read values from real time meteo file 
   $values              = simplexml_load_file($fileMeteo) ;
   //
   // --------------------------------------------
      
   $date             = $values->Date ;
   $time             = $values->Time ;
   $valVariable      = $values->Temperature->Outdoor->Value ;
  
   
   switch(true)
   {
      case stristr($variable, "temperature_outdoor"): $valVariable = $values->Temperature->Outdoor->Value ;
                                                      break ;
      
      case stristr($variable, "humidity_outdoor"):    $valVariable = $values->Humidity->Outdoor->Value ;
                                                      break ;
  
      case stristr($variable, "wind_speed"):          $valVariable = $values->Wind->Value ;
                                                      break ;
  
      case stristr($variable, "wind_direction"):      $valVariable = $values->Wind->Direction->Text ;
                                                      break ;
      
      case stristr($variable, "rain_1hour"):          $valVariable = $values->Rain->OneHour->Value ;
                                                      break ;
      
      case stristr($variable, "pressure"):            $valVariable = $values->Pressure->Value ;
                                                      break ;
      
      default: print "Variable : " . $variable . " not recognized" ;
               print "\n" ;
               exit ;
   }
   
   $value            =  $time . "=" . $valVariable . "\n" ;      
   file_put_contents($fileVariable, $value, FILE_APPEND | LOCK_EX) ;
   
?>
 
</html>
