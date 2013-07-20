<!DOCTYPE html>

<html>
   <head>
      <title>Meteo Monteporzio Casale</title>
      <link rel="stylesheet" href="http://code.jquery.com/mobile/1.0a4.1/jquery.mobile-1.0a4.1.min.css" />
      <link rel="Shortcut icon" href="http://meteomonteporzio.altervista.org/favicon2.png">
      <script src="http://code.jquery.com/jquery-1.5.2.min.js"></script>
      <script src="http://code.jquery.com/mobile/1.0a4.1/jquery.mobile-1.0a4.1.min.js"></script>
      <link rel="stylesheet" href="RealTime.m.css" />
      <script type="text/JavaScript" src="OOMeteoCasaleComm.js"></script> 
   </head>
   
   <body>

   <!-- begin first page -->
   
   <section id="page1" data-role="page">
      <header data-role="header"><h1>Meteo Monteporzio</h1></header>
      <div class="content" data-role="content">
         <!-- <p>First page!</p> -->
      <a href="#page-realtime">Real Time Casale</a></p>
      <a href="#page-config" data-rel="dialog">Configuration</a></p></div>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>
   </section>

   <!-- end first page -->


   <!-- === begin second page ============================================== -->

   <section id="page-realtime" data-role="page">
      <header data-role="header"><h1>Meteo Monteporzio</h1></header>
      <div class="content" data-role="content"><p>Casale Station</p></div>

<!--      <h3>Real Time Measurements</h3> -->
         <ul data-role="listview">
            <li data-role="divider" id="divMeteoDate">Measurement Date</li>
            <li data-role="divider" id="divMeteoTime">Measurement Time</li>
            <li                     id="divMeteoTemp">Measurement Temperature Outdoor</li>
            <li                     id="divMeteoHumidity">Measurement Humidity Outdoor</li>
            <li                     id="divMeteoPressure">Measurement Pressure</li>
            <li                     id="divMeteoWindSpeed">Measurement Wind Speed</li>
            <li                     id="divMeteoWindDirection">Measurement Wind Direction</li>
            <li                     id="divMeteoRain1h">Measurement Rain 1hour</li>
            <li                     id="divMeteoRain24h">Measurement Rain 24hour</li>
         </ul>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>

      <script>
         console.debug("page-realtime") ;
      </script>


   </section>


   <script>
      var handler = new MeteoCasaleComm() ;
      handler.retrieveMeteoData() ;
      
      <!-- ================================================================= -->
      <!-- Page page-realtime retrieval for meteo data -->

      $("#page-realtime").bind("pagebeforeshow", function(event, ui) {
            timerRetrieve = setInterval(handler.retrieveMeteoData, 15000) ;
         });

      <!-- Page page-realtime stop retrieval for meteo data -->
      
      $("#page-realtime").bind("pagehide", function(event, ui) {
            clearInterval(timerRetrieve) ;
         });


      <!-- ================================================================= -->


   </script>


   <!-- === end second page ============================================== -->

   <section id="page-config" data-role="page">
      <header data-role="header"><h1>Meteo Monteporzio</h1></header>
      <div class="content" data-role="content"><p>Configuration page</p></div>
      <footer data-role="footer"><h1>Casale & Beach</h1></footer>
   </section>


   </body>

</html>
