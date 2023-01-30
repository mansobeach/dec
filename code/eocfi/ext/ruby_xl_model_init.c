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


xl_model_id model_id ;

extern VALUE rbException ;
static int iDebug ;


VALUE method_xl_model_init(
                              VALUE self,
                              VALUE mode_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_ruby_xl_model_init\n") ;
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
   long mode ;
   long models[XL_NUM_MODEL_TYPES_ENUM];

   mode            = NUM2LONG(mode_) ;

   status = xl_model_init( &mode,
                           models,
                           &model_id,
                           ierr ) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_ruby_xl_model_init ruby_xl_model_init status: %ld ierr: %li model_id: %ld \n", status, *ierr, model_id) ;
   }
                
   if (status != XL_OK)
   {
      func_id = XL_MODEL_INIT_ID ;
      xl_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }
   
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_ruby_xl_model_init\n") ;  
   }

   return Data_Wrap_Struct(RBASIC(self)->klass, NULL, NULL, &model_id) ;

}

/* -------------------------------------------------------------------------- */
