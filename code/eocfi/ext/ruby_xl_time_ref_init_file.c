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

xl_time_id time_id = {NULL} ;

static int iDebug ;

extern VALUE rbException ;

VALUE method_xl_time_ref_init_file( VALUE self,
                                    VALUE timeModel,
                                    VALUE nFiles,
                                    VALUE timeFile,
                                    VALUE timeInitMode,
                                    VALUE timeRef,
                                    VALUE time0_,
                                    VALUE time1_,
                                    VALUE orbit0_,
                                    VALUE orbit1_,
                                    VALUE strUTC, VALUE isDebugMode) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xl_time_ref_init_file\n") ;
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

   /* --------------------------------------------------- */
   /* xl_time_ref_init_file inputs */
   
   /*
   xl_time_id time_id = {NULL} ;
   */

   long  time_model, 
         n_files, 
         time_init_mode,
         time_ref,
         orbit0,
         orbit1 ;

   /* inputs*/
   double time0, time1 ;
   /* --------------------------------------------------- */
   /* xl_time_ref_init_file outputs */
   double val_time0, val_time1 ;
   /* --------------------------------------------------- */
   char path_time_file[XO_MAX_STR] ;
   char *time_file[1] ;

   n_files     = RARRAY_LEN(timeFile) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_time_ref_init_file checking n_files[%li] coherency\n", n_files) ;  
   }

   if (n_files > 1)
   {
      rb_fatal("ERROR: method_xl_time_ref_init_file => n_files supported cannot be > 1") ;
      return INT2NUM(1) ;
   }

   if (n_files != NUM2LONG(nFiles))
   {
      rb_warn("ERROR: method_xl_time_ref_init_file => inconsistency between n_files & time_file parameters") ;
      n_files     = NUM2LONG(nFiles) ;
   }

   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_time_ref_init_file AFTER checking n_files[%li] coherency\n", n_files) ;  
   }

   time_model     = NUM2LONG(timeModel) ;
   time_init_mode = NUM2LONG(timeInitMode) ;
   time_ref       = NUM2LONG(timeRef) ;
   time0          = NUM2DBL(time0_) ;
   time1          = NUM2DBL(time1_) ;
   orbit0         = NUM2DBL(orbit0_) ;
   orbit1         = NUM2DBL(orbit1_) ;

   for(int idx =0 ; idx < n_files; idx++)
   {
      VALUE entry = rb_ary_entry(timeFile, idx) ;
      char * c_str = StringValueCStr(entry) ;
      strcpy(path_time_file, c_str ) ;
   }

   time_file[0]        = path_time_file ;

   /* --------------------------------------------------- */
   /* Error handling for orbit ephemeris presence */

   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_time_ref_init_file BEFORE checking path_time_file[%s] coherency\n", path_time_file) ;  
   }

   FILE *file;
   if ((file = fopen(path_time_file, "r")))
   {
      if (iDebug == 1)
         printf("DEBUG: method_xl_time_ref_init_file file %s is available\n", path_time_file) ;

      fclose(file) ;
   }
   else
   {
      if (iDebug == 1)
         printf("DEBUG: method_xl_time_ref_init_file file %s not found\n", path_time_file) ;

      rb_raise(rbException, "method_xl_time_ref_init_file file %s not found", path_time_file) ;
      
      /*
      rb_fatal("ERROR: method_xl_time_ref_init_file => cannot open file %s", path_time_file) ; 
      */
   }
   /* --------------------------------------------------- */
 
   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_time_ref_init_file BEFORE xl_time_ref_init_file\n") ;  
   }

   status = xl_time_ref_init_file(  &time_model, 
                                    &n_files, 
                                    time_file,
                                    &time_init_mode, 
                                    &time_ref,
                                    &time0,
                                    &time1,
                                    &orbit0,
                                    &orbit1,
                                    &val_time0, 
                                    &val_time1, 
                                    &time_id,
                                    ierr);

   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_time_ref_init_file xl_time_ref_init_file status: %ld ierr: %li\n", status, *ierr) ;  
   }

   if (status != XO_OK)
   {
      func_id = XL_TIME_REF_INIT_FILE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }

   /* --------------------------------------------------- */

   char strUTCDate [30] ;
   strcpy(strUTCDate, StringValueCStr(strUTC) ) ; 

   
   
   /* orbit initilization */
   /* ------------------- */
   
  
   


   /* ------------------------------------------------------ */
   /* xl_time_ascii_to_processing */

 
  
   /*

 long second_t, microsec_t ; 
  
  long time_mode, orbit_mode ;
   long sat_id ;

   double dTimeProcessing, dTimeStart, dTimeStop ;
   
  
   
   dTimeStart           = -18260.0 ;
   dTimeStop            = 36523.0 ;
  
long ascii_id_in, lProcessingFormat ;

   ascii_id_in          = XL_ASCII_CCSDSA_COMPACT ;
   lProcessingFormat    = XL_PROC ;
   
   status         = xl_time_ascii_to_processing(
                                             &time_id,            // NULL 
                                             &ascii_id_in,        // XL_ASCII_CCSDSA_COMPACT
                                             &time_ref,       // XL_TIME_UTC
                                             strUTCDate,          // 20180720T120000
                                             &lProcessingFormat,  // XL_PROC
                                             &time_ref,       // XL_TIME_UTC
                                             &dTimeProcessing,    // <output>
                                             ierr                 // Error handling
                                             ) ;
   if (status != XO_OK)
   {
      func_id = XL_TIME_ASCII_TO_PROCESSING_ID ;
      xl_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }
   else
   {
      if (iDebug == 1)
         printf("DEBUG: method_xl_time_ref_init_file Successful conversion from %s to %f\n", strUTCDate, dTimeProcessing) ;
   }

   */
  

   /* orbit initialization with an OSF */
   /* -------------------------------- */

   /*
  
   xl_model_id    model_id    = {NULL} ;
   xo_orbit_id    orbit_id    = {NULL} ;


   long lOrbitNumber, lOrbitStart, lOrbitStop ;

   lOrbitStart          = 0 ;
   lOrbitStop           = 99999 ;

   n_files    = 1 ;
   time_mode  = XO_SEL_FILE ;
   orbit_mode = XO_ORBIT_INIT_AUTO ;
   sat_id     = XO_SAT_SENTINEL_2A ;   

   status = xo_orbit_init_file(  &sat_id,
                                 &model_id,
                                 &time_id,
                                 &orbit_mode,
                                 &n_files,          
                                 time_file,           
                                 &time_mode,      
                                 &time_ref,          
                                 &time0, 
                                 &time1, 
                                 &lOrbitStart, 
                                 &lOrbitStop,
                                 &val_time0,
                                 &val_time1,
                                 &orbit_id, 
                                 ierr) ;


   if (iDebug == 1)
   {
      printf("DEBUG: method_xl_time_ref_init_file xo_orbit_init_file status: %ld ierr: %li\n", status, *ierr) ;  
   }                              
                                 
   if (status != XO_OK)
   {
      func_id = XO_ORBIT_INIT_FILE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }


   status = xo_time_to_orbit(&orbit_id, 
                              &time_ref,
                              &dTimeProcessing,
                              &lOrbitNumber, 
                              &second_t, 
                              &microsec_t,
                              ierr) ;

  
   if (status != XO_OK)
   {
      func_id = XO_TIME_TO_ORBIT_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }
   
   xo_orbit_close (&orbit_id, ierr) ;

   if (iDebug == 1)
      printf("DEBUG: method_xl_time_ref_init_file date: %s to orbit number: %ld\n", strUTCDate, lOrbitNumber) ;

   */

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xl_time_ref_init_file\n") ;  
   }

   return Data_Wrap_Struct(RBASIC(self)->klass, NULL, NULL, &time_id) ;

}

/* -------------------------------------------------------------------------- */
