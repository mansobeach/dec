/**
    
#########################################################################
#
# === 20140716 
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
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

   // Classify DOM element divMeteoTemp for CSS format

   // console.debug("pedo") ;

   this.classFormatTemperature(temp) ;

   // console.debug("pis") ;

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
      // document.getElementById("divMeteoTemp").innerHTML = temp ;
      // document.getElementById("divMeteoTemp").value = temp
      
      // document.getElementById("divMeteoTemp").text = temp
      
      // document.getElementById("divMeteoTemp").innerText = temp
      
      // $("divMeteoTemp").text = temp
      
      var anElem = $('a') ;
      
      var aElem = $('a[href$="win_evolution_temperature-outdoor"]');
      var children = aElem.children();

      aElem.text(temp);
      // aElem.append(temp); 
      
      aElem.append(children); 
      
      
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
   // xmlhttp.open("GET", "METEO_LEON.xml", true) ;

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

/**
   Function format   
*/
   
MeteoCasaleComm.prototype.classFormatTemperature = function(temperature)    
{
   var VHot    = 40,
       Hot     = 30,
       VWarm   = 25,
       Warm    = 20,
       Cold    = 0 ;

   iTemp = parseInt(temperature) ;

   console.debug(iTemp) ;
   console.debug(document.getElementById("divMeteoTemp").className) ;

   document.getElementById("divMeteoTemp").className.replace("TemperatureVeryHot", "") ;
   document.getElementById("divMeteoTemp").className.replace("TemperatureHot", "") ;
   document.getElementById("divMeteoTemp").className.replace("TemperatureVeryWarm", "") ;
   document.getElementById("divMeteoTemp").className.replace("TemperatureWarm", "") ;
   
   document.getElementById("divMeteoTemp").classList.remove("TemperatureWarm") ;
   document.getElementById("divMeteoTemp").classList.remove("TemperatureVeryWarm") ;
   
   console.debug(document.getElementById("divMeteoTemp").className) ;
   
    
   if (iTemp >= VHot)
   {
      console.debug("very hot") ;

      if (document.getElementById("divMeteoTemp").className.indexOf("TemperatureVeryHot") == -1)
      {
         document.getElementById("divMeteoTemp").className += " TemperatureVeryHot" ;
         $("#divMeteoTemp").css({"color":"red"}) ;
      }
   }
   else if(iTemp >= Hot)
   {
      console.debug("hot") ;

      if (document.getElementById("divMeteoTemp").className.indexOf("TemperatureHot") == -1)
      {
         document.getElementById("divMeteoTemp").className += " TemperatureHot" ;
         $("#divMeteoTemp").css({"color":"red"}) ;
      }
   } 
   else if(iTemp >= VWarm)
   {
      console.debug("very warm") ;

      if (document.getElementById("divMeteoTemp").className.indexOf("TemperatureVeryWarm") == -1)
      {
         document.getElementById("divMeteoTemp").className += " TemperatureVeryWarm" ;
         $("#divMeteoTemp").css({"color":"orangered"}) ;
      }
   } 
   else if(iTemp >= Warm)
   {
      console.debug("warm") ;

      if (document.getElementById("divMeteoTemp").className.indexOf("TemperatureWarm") == -1)
      {
         document.getElementById("divMeteoTemp").className += " TemperatureWarm" ;
         $("#divMeteoTemp").css({"color":"orange"}) ;
      }
   } 

   console.debug(document.getElementById("divMeteoTemp").className) ;

}
//==============================================================================
