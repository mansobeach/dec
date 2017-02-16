#!/bin/bash

URL_METEO="meteomonteporzio.altervista.org/update_daily_values.php?variable="

echo
echo "Casale & Beach - Meteo Casale update variables"
echo
 
for VARIABLE in "temperature_outdoor" "humidity_outdoor" "pressure" "wind_speed" "wind_direction" "rain_1hour" "rain_24hour"
do
   echo "curl --silent $URL_METEO$VARIABLE"
   curl --silent $URL_METEO$VARIABLE
   RETVAL=$?
   # echo $RETVAL
done

exit
