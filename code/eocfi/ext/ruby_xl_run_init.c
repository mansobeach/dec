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

#include <explorer_orbit.h>
#include <explorer_data_handling.h>
#include <explorer_lib.h>

long run_id ;
extern xo_orbit_id orbit_id ;
extern xl_model_id model_id ;

extern VALUE rbException ;
extern xl_time_id time_id ;
static int iDebug ;


VALUE method_xl_run_init(
                              VALUE self,
                              VALUE sat_id_,
                              VALUE time_id_,
                              VALUE model_id_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_ruby_xl_run_init\n") ;
   }

   /* --------------------------------------------------- */
   /* error handling */
   long status,
       ierr[XL_NUM_ERR_RUN_INIT],
       n,
       func_id ; /* Error codes vector */
   
   /* --------------------------------------------------- */
   /* Error messages vector */
   char msg[XL_MAX_COD][XL_MAX_STR] ; 
   /* --------------------------------------------------- */

   long  sat_id ;
   sat_id            = NUM2LONG(sat_id_) ;

   status = xl_run_init(   &sat_id,
                           &time_id,
                           &model_id,
                           &run_id,
                           ierr ) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: method_ruby_xl_run_init ruby_xl_run_init status: %ld ierr: %li run_id: %li \n", status, *ierr, run_id) ;
   }
                
   if (status != XL_OK)
   {
      func_id = XL_RUN_INIT_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }
   
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_ruby_xl_run_init\n") ;  
   }

   return LONG2NUM(run_id) ;

}

/* -------------------------------------------------------------------------- */
