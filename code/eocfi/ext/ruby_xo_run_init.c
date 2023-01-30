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

extern long run_id ;
extern xo_orbit_id orbit_id ;
static int iDebug ;



VALUE method_xo_run_init(
                              VALUE self,
                              VALUE run_id_,
                              VALUE orbit_id_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_ruby_xo_run_init\n") ;
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

   status = xo_run_init(   &run_id,
                           &orbit_id,
                           ierr ) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: method_ruby_xo_run_init ruby_xo_run_init status: %ld ierr: %li\n", status, *ierr) ;
   }
                
   if (status != XO_OK)
   {
      func_id = XO_RUN_INIT_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }
   
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_ruby_xo_run_init\n") ;  
   }

   return LONG2NUM(run_id) ;

}

/* -------------------------------------------------------------------------- */
