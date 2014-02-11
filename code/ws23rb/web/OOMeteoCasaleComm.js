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
   // console.debug("parseMeteoData() entry") ;
   
   // console.debug(xmlResp) ;

   var xml           = $jQuery.parseXML(xmlResp) ;
   var date          = $jQuery(xml).find('Date').first().text() ;
   var aTime         = $jQuery(xml).find('Time').first().text() ;
   var temp          = $jQuery(xml).find('Temperature').find('Outdoor').find('Value').text() ;
   var windspeed     = $jQuery(xml).find('Wind').find('Value').text() ;
   var winddirection = $jQuery(xml).find('Wind').find('Direction').find('Text').text() ;
   var humidity      = $jQuery(xml).find('Humidity').find('Outdoor').find('Value').text() ;
   var rain1h        = $jQuery(xml).find('Rain').find('OneHour').find('Value').text() ;
   var rain24h       = $jQuery(xml).find('Rain').find('TwentyFourHour').find('Value').text() ;
   var pressure      = $jQuery(xml).find('Pressure').find('Value').text() ;

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

   console.debug("SUPERPEDO") ;
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
      // $jQuery('#divMeteoTemp').text(temp) ;         
      $jQuery('a#divMeteoTempLink').text(temp) ;
   }
   catch(e)
   {
      console.error(e) ;
   }

   try
   {
      // document.getElementById("divMeteoWindSpeed").innerHTML = windspeed ;
      $jQuery('a#divMeteoWindSpeedLink').text(windspeed) ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      // document.getElementById("divMeteoWindDirection").innerHTML = winddirection ;
      $jQuery('a#divMeteoWindDirectionLink').text(winddirection) ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      // document.getElementById("divMeteoHumidity").innerHTML = humidity ;
      // $jQuery('#divMeteoHumidity').text(humidity) ;         
      $jQuery('a#divMeteoHumidityLink').text(humidity) ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      // document.getElementById("divMeteoPressure").innerHTML = pressure ;
      $jQuery('a#divMeteoPressureLink').text(pressure) ;
   }
   catch(e)
   {
      console.error(e) ;
   }
   
   try
   {
      document.getElementById("divMeteoRain1h").innerHTML = rain1h ;
      $jQuery('a#divMeteoRain1hLink').text(rain1h) ;
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


   // console.debug("parseMeteoData() exit") ;
   return aMeteoGauge ;
}


//==============================================================================

/**
   Function retrieveMeteoData   
*/
   
MeteoCasaleComm.prototype.retrieveMeteoData = function()    
{
   // console.debug("retrieveMeteoData() entry") ;
 
   new Ajax.Request('/METEO_LEON.xml', {
      method:'get',
      onSuccess: function(transport) {
         MeteoCasaleComm.prototype.parseMeteoData(transport.responseText) ;
         console.debug("$jQuery('#ul').listview('refresh')") ;
         $jQuery('#ul').listview('refresh') ;
      },
      onFailure: function() { console.error("Error when retrieving METEO_LEON.xml") ; }
   });

   // console.debug("retrieveMeteoData() exit") ;
   return ;

}
//==============================================================================

MeteoCasaleComm.prototype.retrieveMeteoData22 = function()    
{
   var xmlhttp    = new XMLHttpRequest() ;
   var xmlResp    = null ;

   // xmlhttp.open("GET", "METEO_CASALE.xml", true) ;
   xmlhttp.open("GET", "METEO_LEON.xml", true) ;

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
