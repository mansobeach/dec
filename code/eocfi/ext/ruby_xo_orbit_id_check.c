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

VALUE method_xo_orbit_id_check(
                              VALUE self,
                              VALUE orbit_id_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xo_orbit_id_check\n") ;
   }

   xd_orbit_file_diagnostics_settings diagnostics_settings ; 
   xo_orbit_id_check_report report_orbit_id ;

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

   status = xo_orbit_id_check(   &orbit_id,
                                 &diagnostics_settings,
                                 &report_orbit_id,
                                 ierr) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xo_orbit_id_check xo_orbit_id_check status: %ld ierr: %li\n", status, *ierr) ;
   }
                                 
   if (status != XO_OK)
   {
      func_id = XO_ORBIT_ID_CHECK_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }

  
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xo_orbit_id_check\n") ;  
   }

   return LONG2NUM(status) ;

}

/* -------------------------------------------------------------------------- */
