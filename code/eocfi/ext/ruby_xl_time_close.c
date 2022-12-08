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

#include <explorer_orbit.h>

extern xl_time_id time_id ;
static int iDebug ;

VALUE method_xl_time_close(
                           VALUE self,
                           VALUE isDebugMode
                           ) 
{
 
   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xl_time_close\n") ;  
   }
   
   long ierr[XL_NUM_ERR_TIME_CLOSE], status;

   status = xl_time_close(
                           &time_id,
                           ierr
                        ) ;
  
   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_time_close xl_time_close status: %ld ierr: %li\n", status, *ierr) ;  
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT ruby_method_xl_time_close\n") ;
   }
   
   return LONG2NUM(status) ;
}

