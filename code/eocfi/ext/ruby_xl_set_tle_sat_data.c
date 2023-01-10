/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER DATA HANDLING CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
#
#
#########################################################################

*/

#include <ruby.h>

#include <explorer_orbit.h>

static int iDebug ;
extern VALUE rbException ;

VALUE method_xl_set_tle_sat_data(
                                          VALUE self,
                                          VALUE sat_id_,
                                          VALUE norad_sat_number_,
                                          VALUE satellite_name_,
                                          VALUE int_des_,
                                          VALUE isDebugMode
                                          ) 
{
 
   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_method_xl_set_tle_sat_data\n") ;  
   }
   
   /* --------------------------------------------------- */

   long sat_id, norad_sat_number ;
   /* --------------------------------------------------- */
   /* error handling */
   long n,
   func_id ; /* Error codes vector */
   /* --------------------------------------------------- */
   char msg[XD_MAX_COD][XD_MAX_STR] ; /* Error messages vector */
   /* --------------------------------------------------- */
   long ierr[XD_ERR_VECTOR_MAX_LENGTH] ;
   long status ;
   /* --------------------------------------------------- */

   char norad_satcat[25] ;
   char int_des[9] ;
   
   sat_id            = NUM2LONG(sat_id_) ;
   norad_sat_number  = NUM2LONG(norad_sat_number_) ;
   strcpy(norad_satcat, StringValueCStr(satellite_name_)) ;
   strcpy(int_des, StringValueCStr(int_des_)) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ruby_method_xl_set_tle_sat_data sat_id       : %ld\n", sat_id) ;
      printf("DEBUG: ruby_method_xl_set_tle_sat_data sat_id       : %ld\n", norad_sat_number) ;
      printf("DEBUG: ruby_method_xl_set_tle_sat_data norad_satcat : %s\n", norad_satcat) ;
      printf("DEBUG: ruby_method_xl_set_tle_sat_data int_des      : %s\n", int_des) ;  
   }
   
   
   /* --------------------------------------------------- */


   /* --------------------------------------------------- */
   
   status = xl_set_tle_sat_data(
                                       &sat_id,
                                       &norad_sat_number,
                                       norad_satcat,
                                       int_des
                                       ) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_set_tle_sat_data xl_set_tle_sat_data status: %ld\n", status) ;  
   }

   if (status != XD_OK)
   {
      func_id = XD_READ_TLE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT ruby_method_xl_set_tle_sat_data\n") ;
   }

   return LONG2NUM(status) ;

}

/* -------------------------------------------------------------------------- */
