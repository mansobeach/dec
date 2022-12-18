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

VALUE method_xo_orbit_id_check(
                              VALUE self,
                              VALUE orbit_id_,
                              VALUE abs_orbit_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xo_orbit_id_check\n") ;
   }

   /* inputs */
   /* orbit_id */
   long abs_orbit ;

   if (TYPE(abs_orbit_) == T_FIXNUM)
      abs_orbit = NUM2LONG(abs_orbit_) ;
   else
      rb_fatal("method_xo_orbit_id_check abs_orbit is not a long type compatible (T_FIXNUM) but %i", TYPE(abs_orbit_)) ;

   /* output */
   double result[XO_ORBIT_INFO_EXTRA_NUM_ELEMENTS] ;

   /* --------------------------------------------------- */
   /* error handling */
   long status,
       ierr[XO_ERR_VECTOR_MAX_LENGTH],
       n,
       func_id ; /* Error codes vector */
   
   /* --------------------------------------------------- */
   /* Error messages vector */
   char msg[XO_MAX_COD][XO_MAX_STR] ; 
   /* --------------------------------------------------- */

   status = xo_orbit_id_check( &orbit_id,
                           &abs_orbit,
                           result,
                           ierr) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xo_orbit_id_check method_xo_orbit_id_check status: %ld ierr: %li\n", status, *ierr) ;
   }
                                 
   if (status != XO_OK)
   {
      func_id = XO_ORBIT_INFO_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }

   if (iDebug == 1)
   {
      for (int idx = 0 ; idx < XO_ORBIT_INFO_EXTRA_NUM_ELEMENTS; idx++)
      {
         printf("DEBUG: result[%i] = %f \n", idx, result[idx]) ;
      }
   }

   VALUE arrResult = rb_ary_new2(XO_ORBIT_INFO_EXTRA_NUM_ELEMENTS) ;

   for (int idx = 0 ; idx < XO_ORBIT_INFO_EXTRA_NUM_ELEMENTS; idx++)
   {
      if (iDebug == 1)
         printf("DEBUG: result[%i] = %f \n", idx, result[idx]) ;

      rb_ary_store(arrResult, idx, rb_float_new(result[idx]) ) ;
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xo_orbit_id_check\n") ;  
   }

   return arrResult ;

}

/* -------------------------------------------------------------------------- */
