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

#include <explorer_visibility.h>


xv_swath_info swath_info;
extern xl_time_id time_id ;
static int iDebug ;

VALUE method_xv_swath_id_init(
                           VALUE self,
                           VALUE isDebugMode
                           )
{
 
   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xv_swath_id_init\n") ;  
   }
   
   xp_atmos_id atmos_id = {NULL};
   xv_swath_id swath_id = {NULL};
  
   /* --------------------------------------------------- */
   /* error handling */
   long status,
       ierr[XV_NUM_ERR_SWATH_ID_INIT],
       n,
       func_id ; /* Error codes vector */
   /* --------------------------------------------------- */

   /* Error messages vector */
   char msg[XV_MAX_COD][XV_MAX_STR] ; 
   /* --------------------------------------------------- */

   status = xv_swath_id_init( &swath_info,
                              &atmos_id,
                              &swath_id,
                              ierr);

   if (iDebug == 1)
   {
      printf("DEBUG: method_xv_swath_id_init xv_swath_id_init status: %ld ierr: %li\n", status, *ierr) ;  
   }

   if (status != XV_OK)
   {
      func_id = XV_SWATH_ID_INIT_ID ;
      xv_get_msg(&func_id, ierr, &n, msg) ;
      xv_print_msg(&n, msg) ;
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xv_swath_id_init\n") ;
   }
   
   return LONG2NUM(status) ;
}

