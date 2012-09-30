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

*/

//==============================================================================

/**
   Function retrieveMeteoData   
*/
   
function retrieveMeteoData()       
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
            parseMeteoData(xmlhttp.responseText) ;
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

/**
   Function parseMeteoData   
*/

function parseMeteoData(xmlResp)
{   
   document.getElementById("divMeteoData").innerHTML = xmlResp ;
   
   var xml  = $.parseXML(xmlResp) ;
   var date = $(xml).find('Date').first().text() ;
   var time = $(xml).find('Time').first().text() ;
   var temp = $(xml).find('Temperature').find('Outdoor').find('Value').text() ;

   console.debug(date + " " + time + " " + temp + " degrees Celsius") ;

}

//==============================================================================
