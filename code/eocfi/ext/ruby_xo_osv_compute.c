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

VALUE method_xo_osv_compute(
                              VALUE self,
                              VALUE orbit_id_,
                              VALUE mode_,
                              VALUE time_ref_,
                              VALUE time_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xo_osv_compute\n") ;
   }

   /* inputs */
   long mode, time_ref ;
   double time ;

   mode     = NUM2LONG(mode_) ;
   time_ref = NUM2LONG(time_ref_) ;
   time     = NUM2DBL(time_) ;

   /* output */
   double pos_out[3], vel_out[3], acc_out[3] ;

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

   status = xo_osv_compute( &orbit_id,
                           &mode,
                           &time_ref,
                           &time,
                           pos_out,
                           vel_out,
                           acc_out,
                           ierr) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xo_osv_compute xo_osv_compute status: %ld ierr: %li\n", status, *ierr) ;
   }
                                 
   if (status != XO_OK)
   {
      func_id = XO_OSV_COMPUTE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }

   if ( (status == XO_OK) && (iDebug == 1) )
   {
      printf("DEBUG: method_xo_osv_compute\t-  time = %lf \n", time );
      printf("DEBUG: method_xo_osv_compute\t-  Earth Fixed Coordinate System: \n") ;
      printf("DEBUG: method_xo_osv_compute\t-  pos[0] = %lf metres \n", pos_out[0] );
      printf("DEBUG: method_xo_osv_compute\t-  pos[1] = %lf metres \n", pos_out[1] );
      printf("DEBUG: method_xo_osv_compute\t-  pos[2] = %lf metres \n", pos_out[2] );
      printf("DEBUG: method_xo_osv_compute\t-  vel[0] = %lf m/s \n", vel_out[0] );
      printf("DEBUG: method_xo_osv_compute\t-  vel[1] = %lf m/s \n", vel_out[1] );
      printf("DEBUG: method_xo_osv_compute\t-  vel[2] = %lf m/s \n", vel_out[2] );
      printf("DEBUG: method_xo_osv_compute\t-  acc[0] = %lf m/s^2 \n", acc_out[0] );
      printf("DEBUG: method_xo_osv_compute\t-  acc[1] = %lf m/s^2 \n", acc_out[1] );
      printf("DEBUG: method_xo_osv_compute\t-  acc[2] = %lf m/s^2 \n", acc_out[2] );
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xo_osv_compute\n") ;  
   }

   return LONG2NUM(status) ;

}

/* -------------------------------------------------------------------------- */
