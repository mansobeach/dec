/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER_ORBIT CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
#
# === Elecnor-Deimos
# 
#
#########################################################################

*/

#include <ruby.h>

#include <explorer_data_handling.h>
#include <explorer_orbit.h>

extern xo_orbit_id orbit_id ;
static int iDebug ;

VALUE method_xo_orbit_init_status(
                              VALUE self,
                              VALUE orbit_id_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xo_orbit_init_status\n") ;
   }

   /* --------------------------------------------------- */
   /* error handling */
   long status,
       ierr[XO_NUM_ERR_ORBIT_ID_CHECK],
       n,
       func_id ; /* Error codes vector */
   
   /* --------------------------------------------------- */
   /* Error messages vector */
   char msg[XO_MAX_COD][XO_MAX_STR] ; 
   /* --------------------------------------------------- */

   status = xo_orbit_init_status( &orbit_id ) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: method_xo_orbit_init_status xo_orbit_init_status( orbit_id:%ld ) status: %ld \n", orbit_id, status) ;
   }

   /*
                   
   if (status != XO_OK)
   {
      func_id = XO_ORBIT_ID_CHECK_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }
   
   */
  
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xo_orbit_init_status\n") ;  
   }

   return LONG2NUM(status) ;

}

/* -------------------------------------------------------------------------- */
