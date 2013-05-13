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
   var humidity      = $(xml).find('Humidity').find('Outdoor').find('Value').text() ;
   var rain1h        = $(xml).find('Rain').find('OneHour').find('Value').text() ;
   var pressure      = $(xml).find('Pressure').find('Value').text() ;

   var aMeteoGauge   = new Object() ;   

   aMeteoGauge.date           = date ;
   aMeteoGauge.time           = aTime ;
   aMeteoGauge.temperature    = temp ;
   aMeteoGauge.windspeed      = windspeed ;
   aMeteoGauge.humidity       = humidity ;
   aMeteoGauge.pressure       = pressure ;
   aMeteoGauge.rain1h         = rain1h ;

   // add units
   temp        = temp + " \u00BA" + "C" ;
   windspeed   = windspeed + " Km/h" ;
   humidity    = humidity + " %" ;
   rain1h      = rain1h + " mm/h" ;
   pressure    = pressure + " hPa" ;

   console.debug(date + " " + aTime + " " + temp) ;

   document.getElementById("divMeteoDate").innerHTML = date ;
   document.getElementById("divMeteoTime").innerHTML = aTime ;
   document.getElementById("divMeteoTemp").innerHTML = temp ;
   document.getElementById("divMeteoWindSpeed").innerHTML = windspeed ;
   document.getElementById("divMeteoHumidity").innerHTML = humidity ;
   document.getElementById("divMeteoPressure").innerHTML = pressure ;
   document.getElementById("divMeteoRain1h").innerHTML = rain1h ;

   this.arrayMeteoGauges.push(aMeteoGauge) ;

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
            // alert("Error" + xmlhttp.status) ;
         }        
      }
   }
   xmlhttp.send(null) ;
}
//==============================================================================
