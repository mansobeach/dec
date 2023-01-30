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


extern xl_model_id model_id ;

extern VALUE rbException ;
static int iDebug ;


VALUE method_xl_model_get_data(
                              VALUE self,
                              VALUE model_id_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_ruby_xl_model_get_data\n") ;
   }

   /* --------------------------------------------------- */
   /* --------------------------------------------------- */
   
   long status ;
   xl_model_data data ;

   status = xl_model_get_data(
                              &model_id,
                              &data
                                 ) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_ruby_xl_model_get_data ruby_xl_model_get_data status: %ld model_id: %p \n", status, (void *) &model_id) ;
   }
                
   if (status != XL_OK)
   {
      printf("\nERROR TO BE HANDLED !\n") ;
   }

   if (status == XL_OK && iDebug == 1)
   {
      printf("DEBUG: xl_model_get_data Earth model        : %ld\n", data.earth_model) ;
      printf("DEBUG: xl_model_get_data Sun model          : %ld\n", data.sun_model) ;
      printf("DEBUG: xl_model_get_data Moon  model        : %ld\n", data.moon_model) ;
      printf("DEBUG: xl_model_get_data Planet model       : %ld\n", data.planet_model) ;
      printf("DEBUG: xl_model_get_data Nutation model     : %lf m\n", data.nutation_model) ;
      printf("DEBUG: xl_model_get_data Precession model   : %lf m\n", data.precession_model) ;
      printf("DEBUG: xl_model_get_data Constants model    : %lf m\n", data.constants_model) ;
      printf("DEBUG: xl_model_get_data Earth radius       : %lf m\n", data.re) ;
      printf("DEBUG: xl_model_get_data Earth major axis   : %lf m\n", data.major_axis) ;
      printf("DEBUG: xl_model_get_data Earth minor axis   : %lf m\n", data.minor_axis) ;
   }
   
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_ruby_xl_model_get_data\n") ;  
   }

   return Data_Wrap_Struct(RBASIC(self)->klass, NULL, NULL, &model_id) ;

}

/* -------------------------------------------------------------------------- */
