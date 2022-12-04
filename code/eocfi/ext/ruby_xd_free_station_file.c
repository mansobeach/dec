/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER_ORBIT CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
#
#
#########################################################################

*/

#include <ruby.h>

#include <explorer_data_handling.h>


VALUE method_xd_free_station_file(
                                          VALUE self,
                                          VALUE xdStationFile,
                                          VALUE isDebugMode
                                          ) 
{
 
   int iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ruby_method_xd_free_station_file ENTRY\n") ;  
   }
   
   xd_free_station_file(
                           xdStationFile
                        ) ;
  
   if (iDebug == 1)
   {
      printf("DEBUG: ruby_method_xd_free_station_file EXIT\n") ;
   }
      
}

