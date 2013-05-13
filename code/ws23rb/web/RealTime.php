<html>

 <link rel="Shortcut icon" href="http://meteomonteporzio.altervista.org/favicon2.png">

 <head>

   <title>Casale Beach 2012 Real Time Weather</title>

   <META HTTP-EQUIV="Refresh" CONTENT="3600">
   <META HTTP-EQUIV="Expires" CONTENT="0">
   <META HTTP-EQUIV="Pragma"  CONTENT="no-cache">



 


 </head>
 
 <body bgcolor="darkblue">

   Casale Beach Monthly 2012 Charts

<marquee>Meteo Casale</marquee>


   <script src="//ajax.googleapis.com/ajax/libs/dojo/1.8.0/dojo/dojo.js" data-dojo-config="async: true"></script>

 
<!-- <?php  echo '<p>Hello World</p>'; ?>   -->


<!-- ================================================================================ -->
 
require(["dojo/request"], function(request){
    request("helloworld.txt").then(
        function(text){
            console.log("The file's contents is: " + text);
        },
        function(error){
            console.log("An error occurred: " + error);
        }
    );
});

<!-- ================================================================================ -->

 
 </body>
</html>
