<!DOCTYPE html>

<html>
   <head>
      <title>Meteo León</title>
      <link rel="stylesheet" href="http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.css">
      <script src="http://code.jquery.com/jquery-1.8.3.min.js"></script>
      <script src="http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.js"></script>
      <script src="prototype.js"          type="text/javascript"></script>
      <script src="OOMeteoCasaleComm.js"  type="text/JavaScript"></script>
      <script type="text/javascript">
         jQuery.noConflict() ;
         var $jQuery = jQuery ;
      </script>
   </head>
   
   <body>

   <!-- begin first page -->
   
   <section id="page1" data-role="page">
      <header data-role="header"><h1>Meteo León</h1></header>
      <div class="content" data-role="content">
         <!-- <p>First page!</p> -->
      <a href="#page-realtime">Real Time León</a></p>
      <a href="#page-config" data-rel="dialog">Configuration</a></p></div>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>
   </section>

   <!-- end first page -->


   <!-- === begin second page ============================================== -->

   <section id="page-realtime" data-role="page">
      <header data-role="header"><h1>Meteo León</h1></header>
      <div class="content" data-role="content"><p>LEÓN Station</p></div>

<!--      <h3>Real Time Measurements</h3> -->
         <ul data-role="listview" data-inset=true>


            <li data-role="divider" id="divMeteoDate">Measurement Date</li>
            <li data-role="divider" id="divMeteoTime">Measurement Time</li>


            <li id="divMeteoTemp" value="" data-icon=arrow-r><a id="divMeteoTempLink" href=#win_evolution_temperature-outdoor>Measurement Temperature Outdoor</a></li>

            <li id="divMeteoHumidity" data-icon=arrow-r><a id="divMeteoHumidityLink" href=#win_evolution_humidity-outdoor>Measurement Humidity Outdoor</a></li>
            
            <li id="divMeteoPressure" data-icon=arrow-r><a id="divMeteoPressureLink" href=#win_evolution_pressure>Measurement Pressure</a></li>

            <li id="divMeteoWindSpeed" data-icon=arrow-r><a id="divMeteoWindSpeedLink" href=#win_evolution_wind-speed>Measurement Wind Speed</a></li>            
                        
            <li id="divMeteoWindDirection" data-icon=arrow-r><a id="divMeteoWindDirectionLink" href=#win_evolution_wind-direction>Measurement Wind Direction</a></li>
            
            <li id="divMeteoRain1h" data-icon=arrow-r><a id="divMeteoRain1hLink" href=#win_evolution_rain-onehour>Measurement Rain 1hour</a></li>
                        
            <li                     id="divMeteoRain24h">Measurement Rain 24hour</li>
         </ul>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>

      <script>
         console.debug("page-realtime") ;
      </script>


   </section>


   <script>
   <!--   $("#page-realtime").live("pagecreate", function() {$.mobile.addResolutionBreakpoints([400, 600]);}) -->

      console.debug("DEBUG-1") ;  

      var handler = new MeteoCasaleComm() ;
      
      console.debug("DEBUG-2") ;

      handler.retrieveMeteoData() ;
      
      console.debug("DEBUG-3") ;

      setInterval(handler.retrieveMeteoData, 10000) ;

   </script>


   <!-- === end second page ============================================== -->

   <section id="page-config" data-role="page">
      <header data-role="header"><h1>Meteo León</h1></header>
      <div class="content" data-role="content"><p>Configuration page</p></div>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>
   </section>


   <!-- === Daily Evolution - temperature-outdoor ============================================== -->

   <div data-role=page id=win_evolution_temperature-outdoor data-add-back-btn=true>
      <div data-role=header>
         <h1>Temperature Outdoor Evolution</h1>
      </div>

      <div data-role=content>
         <p>LEÓN Station</p>
         
         <img src='data:image/png;base64,<?php echo base64_encode(file_get_contents("DAILY_TEMPERATURE-OUTDOOR_LEON_TODAY.png")); ?>'>
         
      </div>
   </div>

   <!-- === Daily Evolution - humidity-outdoor ============================================== -->

   <div data-role=page id=win_evolution_humidity-outdoor data-add-back-btn=true>
      <div data-role=header>
         <h1>Humidity Outdoor Evolution</h1>
      </div>

      <div data-role=content>
         <p>LEÓN Station</p>
         
         <img src='data:image/png;base64,<?php echo base64_encode(file_get_contents("DAILY_HUMIDITY-OUTDOOR_LEON_TODAY.png")); ?>'>
         
      </div>
   </div>

   <!-- === Daily Evolution - pressure ============================================== -->

   <div data-role=page id=win_evolution_pressure data-add-back-btn=true>
      <div data-role=header>
         <h1>Pressure Evolution</h1>
      </div>

      <div data-role=content>
         <p>LEÓN Station</p>
         
         <img src='data:image/png;base64,<?php echo base64_encode(file_get_contents("DAILY_PRESSURE_LEON_TODAY.png")); ?>'>
         
      </div>
   </div>

   <!-- === Daily Evolution - wind-speed ============================================== -->

   <div data-role=page id=win_evolution_wind-speed data-add-back-btn=true>
      <div data-role=header>
         <h1>Wind Speed Evolution</h1>
      </div>

      <div data-role=content>
         <p>LEÓN Station</p>
         
         <img src='data:image/png;base64,<?php echo base64_encode(file_get_contents("DAILY_WIND-SPEED_LEON_TODAY.png")); ?>'>
         
      </div>
   </div>

   <!-- === Daily Evolution - wind-direction ============================================== -->

   <div data-role=page id=win_evolution_wind-direction data-add-back-btn=true>
      <div data-role=header>
         <h1>Wind Direction Evolution</h1>
      </div>

      <div data-role=content>
         <p>LEÓN Station</p>
         
         <img src='data:image/png;base64,<?php echo base64_encode(file_get_contents("DAILY_WIND-DIRECTION_LEON_TODAY.png")); ?>'>
         
      </div>
   </div>

   <!-- === Daily Evolution - rain-1hour ============================================== -->

   <div data-role=page id=win_evolution_rain-onehour data-add-back-btn=true>
      <div data-role=header>
         <h1>Rain 1Hour Evolution</h1>
      </div>

      <div data-role=content>
         <p>LEÓN Station</p>
         
         <img src='data:image/png;base64,<?php echo base64_encode(file_get_contents("DAILY_RAIN-1HOUR_LEON_TODAY.png")); ?>'>
         
      </div>
   </div>

   <!-- === end second page ============================================== -->

   </body>

</html>
