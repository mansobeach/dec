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

static int iDebug ;

VALUE method_xo_verbose(
                           VALUE self,
                           VALUE isDebugMode
                           ) 
{
 
   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xo_verbose\n") ;  
   }
   
   long status ;

   status = xo_verbose() ;
  
   if (iDebug == 1)
   {
      printf("DEBUG: method_xo_verbose xo_verbose status: %ld\n", status) ;  
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xo_verbose\n") ;
   }
   
   return LONG2NUM(status) ;
}

