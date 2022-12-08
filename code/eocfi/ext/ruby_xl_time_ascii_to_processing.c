/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER_ORBIT CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#########################################################################

*/

#include <ruby.h>

#include <explorer_orbit.h>

extern xl_time_id time_id ;
static int iDebug ;


VALUE method_xl_time_ascii_to_processing( VALUE self,
                                    VALUE ascii_id_in_,
                                    VALUE time_ref_in_,
                                    VALUE ascii_in_,
                                    VALUE proc_id_out_,
                                    VALUE time_ref_out_,
                                    VALUE processing_out_,
                                    VALUE isDebugMode) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xl_time_ascii_to_processing\n") ;
   }

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
   char ascii_in[XO_MAX_STR] ;
   /* --------------------------------------------------- */
   /* xl_time_ascii_to_processing parameters */
   long  ascii_id_in,
         time_ref_in,
         time_ref_out,
         proc_id_out ;
   /* --------------------------------------------------- */
   /* xl_time_ascii_to_processing outputs */
   double processing_out ;
   /* --------------------------------------------------- */
   ascii_id_in     = NUM2LONG(ascii_id_in_) ;
   time_ref_in     = NUM2LONG(time_ref_in_) ;
   strcpy(ascii_in, StringValueCStr(ascii_in_) ) ;
   time_ref_out    = NUM2LONG(time_ref_out_) ;
   proc_id_out     = NUM2LONG(proc_id_out_) ;
   /* --------------------------------------------------- */

   /* ------------------------------------------------------ */
   /* xl_time_ascii_to_processing */
   /* ascii_id_in          = XL_ASCII_CCSDSA_COMPACT ; */
   
   status         = xl_time_ascii_to_processing(
                                             &time_id,            // NULL 
                                             &ascii_id_in,        // XL_ASCII_CCSDSA_COMPACT
                                             &time_ref_in,        // XL_TIME_UTC
                                             ascii_in,            // 20180720T120000
                                             &proc_id_out,        // XL_PROC
                                             &time_ref_out,       // XL_TIME_UTC
                                             &processing_out,     // <output>
                                             ierr                 // Error handling
                                             ) ;
  
   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_time_ascii_to_processing xl_time_ascii_to_processing status: %ld ierr: %li\n", status, *ierr) ;  
   }
  
   if (status != XO_OK)
   {
      func_id = XL_TIME_ASCII_TO_PROCESSING_ID ;
      xl_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }
  
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xl_time_ascii_to_processing\n") ;  
   }

   processing_out_ = LONG2NUM(processing_out);
   return LONG2NUM(processing_out) ;

   
}

/* -------------------------------------------------------------------------- */
