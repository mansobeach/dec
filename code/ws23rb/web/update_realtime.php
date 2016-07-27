<?php

/* =============================================================================        

   Borja Lopez Fernandez
   
   Casale & Beach

   =============================================================================

*/

date_default_timezone_set("Europe/Rome") ;
$currentDate         = date('Ymd') ;
$chartDate           = date('Y-m-d') ;
$chartTime           = date('H:i:s') ;

// $timezone = date_default_timezone_get();
// echo "The current server timezone is: " . $timezone;
// exit ;

$var_station_ip            = htmlspecialchars($_POST["stationIP"]) ;

$var_temperature_outdoor   = htmlspecialchars($_POST["temperature_outdoor"]) ;
$var_pressure_outdoor      = htmlspecialchars($_POST["pressure_outdoor"]) ;
$var_humidity_outdoor      = htmlspecialchars($_POST["humidity_outdoor"]) ;
$var_wind_speed            = htmlspecialchars($_POST["wind_speed"]) ;
$var_wind_direction        = htmlspecialchars($_POST["wind_direction"]) ;
$var_rain_1h               = htmlspecialchars($_POST["rain_24h"]) ;
$var_rain_24h              = htmlspecialchars($_POST["rain_24h"]) ;

// echo $_SERVER['REQUEST_METHOD'] ;
// echo $_SERVER['REQUEST_URI'] ;


$xml = new DOMDocument() ;
$xml -> formatOutput = true ;

$xml_root                  = $xml->createElement("ws2300") ;

$xml_root_attr_simplified  = $xml -> createAttribute('simplified') ;
$xml_root_attr_simplified -> value = 'true' ;
$xml_root -> appendChild( $xml_root_attr_simplified ) ;

$xml_root_attr_stationIP  = $xml -> createAttribute('stationIP') ;
$xml_root_attr_stationIP -> value = $var_station_ip ;
$xml_root -> appendChild( $xml_root_attr_stationIP ) ;

$xml_date                  = $xml->createElement("Date") ;
$xml_date -> nodeValue   = $chartDate ;
$xml_time                  = $xml->createElement("Time") ;
$xml_time -> nodeValue     = $chartTime ;

// -------------------------------------------------------------------
//
// Temperature

$xml_temp                  = $xml->createElement("Temperature") ;
$xml_temp_outdoor          = $xml->createElement("Outdoor") ;
$xml_temp_outdoor_value    = $xml->createElement("Value") ;

$xml_temp_outdoor_value -> nodeValue = $var_temperature_outdoor ;
$xml_temp_outdoor -> appendChild( $xml_temp_outdoor_value ) ;
$xml_temp -> appendChild( $xml_temp_outdoor ) ;

// -------------------------------------------------------------------

// -------------------------------------------------------------------
//
// Humidity

$xml_humidity                  = $xml->createElement("Humidity") ;
$xml_humidity_outdoor          = $xml->createElement("Outdoor") ;
$xml_humidity_outdoor_value    = $xml->createElement("Value") ;

$xml_humidity_outdoor_value -> nodeValue = $var_humidity_outdoor ;
$xml_humidity_outdoor -> appendChild( $xml_humidity_outdoor_value ) ;
$xml_humidity -> appendChild( $xml_humidity_outdoor ) ;

// -------------------------------------------------------------------

// -------------------------------------------------------------------
//
// Pressure

$xml_pressure                  = $xml->createElement("Pressure") ;
$xml_pressure_outdoor_value    = $xml->createElement("Value") ;

$xml_pressure_outdoor_value -> nodeValue = $var_pressure_outdoor ;
$xml_pressure -> appendChild( $xml_pressure_outdoor_value ) ;

// -------------------------------------------------------------------


// -------------------------------------------------------------------
//
// Wind

$xml_wind                      = $xml->createElement("Wind") ;
$xml_wind_speed_value          = $xml->createElement("Value") ;
$xml_wind_speed_value -> nodeValue = $var_wind_speed ;
$xml_wind_direction            = $xml->createElement("Direction") ;
$xml_wind_direction_value      = $xml->createElement("Text") ;
$xml_wind_direction_value -> nodeValue = $var_wind_direction ;

$xml_wind_direction -> appendChild( $xml_wind_direction_value ) ;
$xml_wind -> appendChild( $xml_wind_speed_value ) ;
$xml_wind -> appendChild( $xml_wind_direction ) ;

// -------------------------------------------------------------------

// -------------------------------------------------------------------
//
// Rain

$xml_rain                      = $xml->createElement("Rain") ;
$xml_rain_1h                   = $xml->createElement("OneHour") ;
$xml_rain_1h_value             = $xml->createElement("Value") ;
$xml_rain_1h_value -> nodeValue = $var_rain_1h ;
$xml_rain_1h -> appendChild( $xml_rain_1h_value ) ;

$xml_rain_24h                   = $xml->createElement("TwentyFourHour") ;
$xml_rain_24h_value             = $xml->createElement("Value") ;
$xml_rain_24h_value -> nodeValue = $var_rain_24h ;
$xml_rain_24h -> appendChild( $xml_rain_24h_value ) ;

$xml_rain -> appendChild( $xml_rain_1h ) ;
$xml_rain -> appendChild( $xml_rain_24h ) ;

// -------------------------------------------------------------------

$xml_root -> appendChild( $xml_date ) ;
$xml_root -> appendChild( $xml_time ) ;
$xml_root -> appendChild( $xml_temp ) ;
$xml_root -> appendChild( $xml_humidity ) ;
$xml_root -> appendChild( $xml_wind ) ;
$xml_root -> appendChild( $xml_rain ) ;
$xml_root -> appendChild( $xml_pressure ) ;

$xml ->appendChild( $xml_root ) ;

// print $xml->saveXML() ;

echo $xml -> save("METEO_NOW.xml") ;


?>
