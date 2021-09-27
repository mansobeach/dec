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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#include <explorer_orbit.h>

/*============================================================================*/
/*  EXPCFI check_library_version direct call          */
/*============================================================================*/


VALUE method_xo_check_library_version(VALUE isDebugMode) 
{
   int iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_xo_check_library_version::method_xo_check_library_version\n") ;  
   }
   
   long lValue ;

   lValue = xo_check_library_version() ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT ruby_xo_check_library_version::method_xo_check_library_version\n") ;  
   }
   return LONG2NUM(lValue) ;
}


/* -------------------------------------------------------------------------- */

