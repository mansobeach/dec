
<?php 

$ini_array      = parse_ini_file("RealTime.ini") ;
$meteo_site     = $ini_array['meteo_site'] ;
$meteo_station  = $ini_array['meteo_station'] ;
$meteo_url      = $ini_array['meteo_url'] ;

?>


<!DOCTYPE html>

<html>
   <head>
      <meta charset="utf-8"/>
      
      <!--
      
      <title>Meteo Monteporzio Casale</title>
      
      -->
      
      <title>$ini_array['site']</title>
      
      <link rel="stylesheet" href=<?php echo $meteo_url ; ?>"/RealTime.m.css" type="text/css" />
      
      <link rel="Shortcut icon" href=<?php echo $meteo_url ; ?>"/favicon2.png">
      
      <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, usr-scalable=no">

      <link rel="stylesheet" href="http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.css">
      <script src="http://code.jquery.com/jquery-1.8.3.min.js"></script>
      <script src="http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.js"></script>
            
      <script type="text/JavaScript" src="OOMeteoCasaleComm.js"></script> 

   </head>

   
   <body>
      <script src="http://www.google.com/jsapi"></script>
      <script src="chartkick.js"></script>
      
   <!-- begin first page -->
   
   <section id="page1" data-role="page">
      <header data-role="header"><h1> <?php echo $meteo_site ; ?> </h1></header>
      <div class="content" data-role="content">
         <!-- <p>First page!</p> -->
      <a href="#page-realtime">Real Time <?php echo $meteo_station ; ?> </a></p>
      <a href="#page-config" data-rel="dialog">Configuration</a></p></div>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>
   </section>

   <!-- end first page -->

   <!-- === BEGIN page-realtime ============================================== -->

   <script type="text/javascript">
      
      console.debug("page-realtime init start") ;
      
      var handler = new MeteoCasaleComm() ;
            
      handler.retrieveMeteoData("METEO_NOW.xml") ;
      
      var myTimer = setInterval(function (){
         var myhandler = new MeteoCasaleComm() ;
         myhandler.retrieveMeteoData("METEO_NOW.xml") ;
         }, 10000) ;

      console.debug("page-realtime init end") ;
   </script>

   <script type="text/javascript">
      function clickDailyValue(variable){
         console.debug("clickDailyValue Entry") ;
         console.debug("invoke get_daily_values:" + variable) ;         
         var handler = new MeteoCasaleComm() ;
         handler.getDailyValues(variable) ;
         console.debug("clickDailyValue Exit") ;
         return true ;
      }
   </script>


   <section id="page-realtime" data-role="page">
      <header data-role="header"><h1> <?php echo $meteo_site ; ?> </h1></header>
      <div class="content" data-role="content"><p><?php echo $meteo_station ; ?> Station</p></div>
         <ul data-role="listview">
            <li data-role="divider" id="divMeteoDate">Measurement Date</li>
            <li data-role="divider" id="divMeteoTime">Measurement Time</li>            
            <li data-role="divider" ><a href="#win_evolution_temperature_outdoor" id="divMeteoTemperatureOutdoor" onclick="return clickDailyValue('temperature_outdoor');">Measurement Temperature Outdoor</a></li>
            <li data-role="divider" ><a href="#win_evolution_humidity_outdoor" id="divMeteoHumidity" onclick="return clickDailyValue('humidity_outdoor');">Measurement Humidity Outdoor</a></li>
            <li data-role="divider" ><a href="#win_evolution_pressure" id="divMeteoPressure" onclick="return clickDailyValue('pressure');">Measurement Pressure</a></li>
            <li data-role="divider" ><a href="#win_evolution_wind_speed" id="divMeteoWindSpeed" onclick="return clickDailyValue('wind_speed');">Measurement Wind Speed</a></li>            
            <li data-role="divider" id="divMeteoWindDirection">Measurement Wind Direction</li>       
            <li data-role="divider" ><a href="#win_evolution_rain_1h" id="divMeteoRain1h" onclick="return clickDailyValue('rain_1hour');">Measurement Rain 1hour</a></li>
            <li data-role="divider" ><a href="#win_evolution_rain_24h" id="divMeteoRain24h" onclick="return clickDailyValue('rain_24hour');">Measurement Rain 24hour</a></li>
         </ul>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>
   </section>


`  <!-- === BEGIN page-realtime ============================================== -->


   <!-- === Daily Evolution - temperature-outdoor ============================================== -->

   <div data-role=page id=win_evolution_temperature_outdoor data-add-back-btn=true>
      <div data-role=header>
         <h1>Temperature Outdoor Evolution</h1>
      </div>

      <div data-role=content>
         <p><?php echo $meteo_station ; ?> Station</p>               
         <div id="chart_line_temperature_outdoor" style="height: 300px; text-align: center; color: #999; line-height: 100px; font-size: 10px; font-family: Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif;">Loading...</div>
      </div>

      <script>
         var handler = new MeteoCasaleComm() ;
         handler.getDailyValues("temperature_outdoor") ;
      </script>

   </div>

   <!-- === BEGIN Daily Evolution - humidity-outdoor ============================================== -->
   <div data-role=page id=win_evolution_humidity_outdoor data-add-back-btn=true>
      
      <div data-role=header>
         <h1>Humidity Evolution</h1>
      </div>

      <div data-role=content>
         <p><?php echo $meteo_station ; ?> Station</p>      
         <div id="chart_line_humidity_outdoor" style="height: 300px; text-align: center; color: #999; line-height: 100px; font-size: 10px; font-family: Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif;">Loading...</div>
      </div>
      
      <script>
         var handler = new MeteoCasaleComm() ;
         handler.getDailyValues("humidity_outdoor") ;
      </script>
      
      
   </div>
   <!-- === END Daily Evolution - humidity-outdoor ============================================== -->

   <!-- === BEGIN Daily Evolution - pressure ============================================== -->
   <div data-role=page id=win_evolution_pressure data-add-back-btn=true>
      
      <div data-role=header>
         <h1>Pressure Evolution</h1>
      </div>

      <div data-role=content>
         <p><?php echo $meteo_station ; ?> Station</p>      
         <div id="chart_line_pressure" style="height: 300px; text-align: center; color: #999; line-height: 100px; font-size: 10px; font-family: Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif;">Loading...</div>
      </div>
      
   </div>
   <!-- === END Daily Evolution - pressure ============================================== -->

   <!-- === BEGIN Daily Evolution - wind_speed ============================================== -->
   <div data-role=page id=win_evolution_wind_speed data-add-back-btn=true>
      
      <div data-role=header>
         <h1>Wind Speed Evolution</h1>
      </div>

      <div data-role=content>
         <p><?php echo $meteo_station ; ?> Station</p>      
         <div id="chart_line_wind_speed" style="height: 300px; text-align: center; color: #999; line-height: 100px; font-size: 10px; font-family: Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif;">Loading...</div>
      </div>
      
      <script>
         var handler = new MeteoCasaleComm() ;
         handler.getDailyValues("wind_speed") ;
      </script>      
      
   </div>
   <!-- === END Daily Evolution - wind_speed ============================================== -->

   <!-- === BEGIN Daily Evolution - rain_1h ============================================== -->
   <div data-role=page id=win_evolution_rain_1h data-add-back-btn=true>
      
      <div data-role=header>
         <h1>Rain 1hour Evolution</h1>
      </div>

      <div data-role=content>
         <p><?php echo $meteo_station ; ?> Station</p>      
         <div id="chart_line_rain_1hour" style="height: 300px; text-align: center; color: #999; line-height: 100px; font-size: 10px; font-family: Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif;">Loading...</div>
      </div>
      
      <script>
         var handler = new MeteoCasaleComm() ;
         handler.getDailyValues("rain_1hour") ;
      </script>      
      
      
   </div>
   <!-- === END Daily Evolution - rain_1h ============================================== -->

   <!-- === BEGIN Daily Evolution - rain_24h ============================================== -->
   <div data-role=page id=win_evolution_rain_24h data-add-back-btn=true>
      
      <div data-role=header>
         <h1>Rain 24hour Evolution</h1>
      </div>

      <div data-role=content>
         <p><?php echo $meteo_station ; ?> Station</p>      
         <div id="chart_line_rain_24hour" style="height: 300px; text-align: center; color: #999; line-height: 100px; font-size: 10px; font-family: Lucida Grande, Lucida Sans Unicode, Verdana, Arial, Helvetica, sans-serif;">Loading...</div>
      </div>
      
      <script>
         var handler = new MeteoCasaleComm() ;
         handler.getDailyValues("rain_24hour") ;
      </script>      
      
      
   </div>
   <!-- === END Daily Evolution - rain_24h ============================================== -->



   <!-- === end second page ============================================== -->

   <section id="page-config" data-role="page">
      <header data-role="header"><h1> <?php echo $meteo_site ; ?> </h1></header>
      <div class="content" data-role="content"><p>Configuration page</p></div>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>
   </section>

   <!-- === end second page ============================================== -->

   </body>

</html>


