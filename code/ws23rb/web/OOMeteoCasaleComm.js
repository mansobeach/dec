/**
    
#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################


/**
   Class MeteoCasaleComm Function parseMeteoData
*/

function MeteoCasaleComm() 
{
   console.debug("MeteoCasaleComm::Constructor") ;
   this.arrayMeteoGauges = [] ;
   console.debug("MeteoCasaleComm::Constructor exit") ;
}

//==============================================================================

/**
   Function parseMeteoData
*/

MeteoCasaleComm.prototype.parseMeteoData = function(xmlResp)
{   
   var xml           = $.parseXML(xmlResp) ;
   var date          = $(xml).find('Date').first().text() ;
   var aTime         = $(xml).find('Time').first().text() ;
   var temp          = $(xml).find('Temperature').find('Outdoor').find('Value').text() ;
   var windspeed     = $(xml).find('Wind').find('Value').text() ;
   var winddirection = $(xml).find('Wind').find('Direction').find('Text').text() ;
   var humidity      = $(xml).find('Humidity').find('Outdoor').find('Value').text() ;
   var rain1h        = $(xml).find('Rain').find('OneHour').find('Value').text() ;
   var rain24h       = $(xml).find('Rain').find('TwentyFourHour').find('Value').text() ;
   var pressure      = $(xml).find('Pressure').find('Value').text() ;

   // --------------------------------------------
   // If file content is empty

   if (date == '')
   {
      console.debug("Empty file retrieved from server") ;
      return
   }
   // --------------------------------------------

   var aMeteoGauge   = new Object() ;   

   aMeteoGauge.date           = date ;
   aMeteoGauge.time           = aTime ;
   aMeteoGauge.temperature    = temp ;
   aMeteoGauge.windspeed      = windspeed ;
   aMeteoGauge.winddirection  = winddirection ;
   aMeteoGauge.humidity       = humidity ;
   aMeteoGauge.pressure       = pressure ;
   aMeteoGauge.rain1h         = rain1h ;
   aMeteoGauge.rain24h        = rain24h ;

   // add units
   temp        = temp + " \u00BA" + "C" ;
   windspeed   = windspeed + " Km/h" ;
   humidity    = humidity + " %" ;
   rain1h      = rain1h + " mm/h" ;
   rain24h     = rain24h + " mm/24h" ;
   pressure    = pressure + " hPa" ;

   console.debug(date + " " + aTime + " " + temp) ;

   // ----------------------------------------------------------------
   // Error handing added
   // ----------------------------------------------------------------

   try
   {
      document.getElementById("divMeteoDate").innerHTML = date ;
   }
   catch(e)
   {
      console.error(e) ;
   }

   try
   {
      document.getElementById("divMeteoTime").innerHTML = aTime ;
   }
   catch(e)
   {
      console.error(e) ;
   }

   try
   {
      document.getElementById("divMeteoTemp").innerHTML = temp ;
   }
   catch(e)
   {
      console.error(e) ;
   }

   try
   {
      document.getElementById("divMeteoWindSpeed").innerHTML = windspeed ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      document.getElementById("divMeteoWindDirection").innerHTML = winddirection ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      document.getElementById("divMeteoHumidity").innerHTML = humidity ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      document.getElementById("divMeteoPressure").innerHTML = pressure ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      document.getElementById("divMeteoRain1h").innerHTML = rain1h ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      document.getElementById("divMeteoRain24h").innerHTML = rain24h ;
   }
   catch(e)
   {
      console.error(e) ;
   }

   // this.arrayMeteoGauges.push(aMeteoGauge) ;

   return aMeteoGauge ;
}


//==============================================================================

/**
   Function retrieveMeteoData   
*/
   
MeteoCasaleComm.prototype.retrieveMeteoData = function()    
{
   var xmlhttp    = new XMLHttpRequest() ;
   var xmlResp    = null ;

   xmlhttp.open("GET", "METEO_CASALE.xml", true) ;

   xmlhttp.onreadystatechange=function()
   {  
      if (xmlhttp.readyState == 4)
      {            
         if (xmlhttp.status == 200)
         {
            MeteoCasaleComm.prototype.parseMeteoData(xmlhttp.responseText) ;
         }
         else
         {
            console.error(xmlhttp.status) ;
            // alert("Error" + xmlhttp.status) ;
         }        
      }
   }
   xmlhttp.send(null) ;
}
//==============================================================================
