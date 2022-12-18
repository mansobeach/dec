/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER_ORBIT CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach / Manso Beach
# 
#
#########################################################################

*/

#include <ruby.h>

#include <explorer_orbit.h>

extern xo_orbit_id orbit_id ;
static int iDebug ;

VALUE method_xo_osv_compute_extra(
                              VALUE self,
                              VALUE orbit_id_,
                              VALUE extra_choice_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xo_osv_compute_extra\n") ;
   }

   /* inputs */
   long extra_choice ;

   extra_choice  = NUM2LONG(extra_choice_) ;
   
   /* --------------------------------------------------- */
   /* output */
   double   model_out[XO_ORBIT_EXTRA_NUM_DEP_ELEMENTS], 
            extra_out[XO_ORBIT_EXTRA_NUM_INDEP_ELEMENTS] ;
   /* --------------------------------------------------- */
   /* error handling */
   long status,
       ierr[XO_NUM_ERR_OSV_COMPUTE],
       n,
       func_id ; /* Error codes vector */
   
   /* --------------------------------------------------- */
   /* Error messages vector */
   char msg[XO_MAX_COD][XO_MAX_STR] ; 
   /* --------------------------------------------------- */

   status = xo_osv_compute_extra( &orbit_id,
                           &extra_choice,
                           model_out,
                           extra_out,
                           ierr) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xo_osv_compute_extra xo_osv_compute_extra status: %ld ierr: %li\n", status, *ierr) ;
   }
                                 
   if (status != XO_OK)
   {
      func_id = XO_OSV_COMPUTE_EXTRA_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }

   VALUE arrResult = rb_ary_new2(XO_ORBIT_EXTRA_NUM_DEP_ELEMENTS+XO_ORBIT_EXTRA_NUM_INDEP_ELEMENTS) ;
   int idx = 0 ;

   if (status == XO_OK)
   {
      for (n=0; n < XO_ORBIT_EXTRA_NUM_INDEP_ELEMENTS; n++)
      {
         if (iDebug == 1) 
            printf("DEBUG: method_xo_osv_compute_extra\t- orbit_extra_out[%ld] = %lf \n", n, extra_out[n] ) ;

         rb_ary_store(arrResult, idx, rb_float_new(extra_out[n]) ) ;
         idx++;
      }

      for (n=0; n<XO_ORBIT_EXTRA_NUM_DEP_ELEMENTS; n++)
      {
         if (iDebug == 1) 
            printf("DEBUG: method_xo_osv_compute_extra\t- orbit_model_out[%ld] = %lf \n", n, model_out[n] ) ;
         
         rb_ary_store(arrResult, idx, rb_float_new(extra_out[n]) ) ;
         idx++;
      }
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xo_osv_compute_extra\n") ;  
   }

   return arrResult ;

}

/* -------------------------------------------------------------------------- */
