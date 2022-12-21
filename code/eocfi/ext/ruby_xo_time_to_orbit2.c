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

#include <explorer_orbit.h>


/*============================================================================*/
/*  EOCFI::xo_time_to_orbit 
      - full_path_OSF
      - UTC date in format 20201220T120000 (XL_ASCII_CCSDSA_COMPACT)         */
/*============================================================================*/


VALUE method_xo_time_to_orbit2(VALUE self, VALUE strROEF, VALUE strUTC, VALUE isDebugMode) 
{

   int iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_xo_time_to_orbit::method_xo_time_to_orbit2\n") ;  
   }

   char strUTCDate [30] ;
   strcpy(strUTCDate, StringValueCStr(strUTC) ) ; 
   
   char path_orbit_file[XO_MAX_STR] ;   
   strcpy(path_orbit_file, StringValueCStr(strROEF) ) ;

   /* =============================== */

   /* Error handling for orbit ephemeris presence */
   FILE *file;
   if ((file = fopen(path_orbit_file, "r")))
   {
      fclose(file) ;
   }
   else
   {
     return LONG2NUM(-1) ;
   }

   /* =============================== */

   /*
   printf("\n") ;
   printf("DEBUG: entry ruby_earth_explorer_cfi::method_DateTime2OrbitAbsolute \n" ) ;
   printf("OSF/POF   => %s\n", path_orbit_file) ;
   printf("Date      => %s\n", strUTCDate) ;
   printf("\n") ;
   */

   
   xl_model_id    model_id    = {NULL} ;
   xl_time_id     time_id     = {NULL} ;
   xo_orbit_id    orbit_id    = {NULL} ;

   /* --------------------------------------------------- */
   /* error handling */
   long status,
       ierr[XO_ERR_VECTOR_MAX_LENGTH],
       n,
       func_id ; /* Error codes vector */
   /* --------------------------------------------------- */
   char msg[XO_MAX_COD][XO_MAX_STR] ; /* Error messages vector */
   /* --------------------------------------------------- */
   /* orbit initilization */
   /* ------------------- */
   long time_mode, orbit_mode ;
   long sat_id ;
   /* --------------------------------------------------- */
   /* --------------------------------------------------- */
   /* xo_time_to_orbit & xo_orbit_to_time variables */
   long second_t, microsec_t ; 
   /* --------------------------------------------------- */
   /* xl_time_ref_init_file */
   
   long   time_model, n_files, time_init_mode ;
   char   *orbit_file[1] ;
   
   long lOrbitNumber, lOrbitStart, lOrbitStop ;

   double time0,
         time1,  
         val_time0,
         val_time1 ;

   long ascii_id_in, lProcessingFormat ;

   long time_ref_utc ;
   
   double dTimeProcessing, dTimeStart, dTimeStop ;
   
   sat_id               = XO_SAT_SENTINEL_2A ;   
   
   lOrbitStart          = 0 ;
   lOrbitStop           = 99999 ;
   
   dTimeStart           = -18260.0 ;
   dTimeStop            = 36523.0 ;
   /* time_model           = XL_TIMEMOD_OSF ; */
   time_model           = XL_TIMEMOD_AUTO ;
   n_files              = 1 ;
   time_init_mode       = XL_SEL_FILE ;
   time_ref_utc         = XL_TIME_UTC ;
   orbit_file[0]        = path_orbit_file ;


   status = xl_time_ref_init_file(  &time_model, 
                                    &n_files, 
                                    orbit_file,
                                    &time_init_mode, 
                                    &time_ref_utc, 
                                    &dTimeStart, 
                                    &dTimeStop,
                                    &lOrbitStart, 
                                    &lOrbitStop, 
                                    &dTimeStart, 
                                    &dTimeStop, 
                                    &time_id,
                                    ierr);
   if (status != XO_OK)
   {
      func_id = XL_TIME_REF_INIT_FILE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }


   /* ------------------------------------------------------ */
   /* xl_time_ascii_to_processing */

   ascii_id_in          = XL_ASCII_CCSDSA_COMPACT ;
   lProcessingFormat    = XL_PROC ;
   
   status         = xl_time_ascii_to_processing(
                                             &time_id,            // NULL 
                                             &ascii_id_in,        // XL_ASCII_CCSDSA_COMPACT
                                             &time_ref_utc,       // XL_TIME_UTC
                                             strUTCDate,          // 20180720T120000
                                             &lProcessingFormat,  // XL_PROC
                                             &time_ref_utc,       // XL_TIME_UTC
                                             &dTimeProcessing,    // <output>
                                             ierr                 // Error handling
                                             ) ;
   if (status != XO_OK)
   {
      func_id = XL_TIME_ASCII_TO_PROCESSING_ID ;
      xl_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }
   /*
   else
   {
      printf("\n\n\nSuccessful conversion from %s to %f\n\n\n\n", strUTCDate, dTimeProcessing) ;
   }
*/


   /* orbit initialization with an OSF */
   /* -------------------------------- */
   n_files    = 1 ;
   time_mode  = XO_SEL_FILE ;
   orbit_mode = XO_ORBIT_INIT_AUTO ;
   

   status = xo_orbit_init_file(  &sat_id,             // XO_SAT_SENTINEL_2A
                                 &model_id,           // NULL 
                                 &time_id,            // NULL
                                 &orbit_mode,         // XO_ORBIT_INIT_AUTO
                                 &n_files,            // 1
                                 orbit_file,          // Array of one OSF
                                 &time_mode,          // XO_SEL_FILE
                                 &time_ref_utc,       // XL_TIME_UTC
                                 &time0, 
                                 &time1, 
                                 &lOrbitStart, 
                                 &lOrbitStop,
                                 &val_time0,
                                 &val_time1,
                                 &orbit_id, 
                                 ierr) ;
                                 
   if (status != XO_OK)
   {
      func_id = XO_ORBIT_INIT_FILE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }


   status = xo_time_to_orbit(&orbit_id, 
                              &time_ref_utc,
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

   /* --------------------------- */
   /* Free Memory */
   /* --------------------------- */
   
   xl_time_close(&time_id, ierr) ;
   
   xo_orbit_close (&orbit_id, ierr) ;

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT ruby_xo_time_to_orbit::method_xo_time_to_orbit2\n") ;  
   }

   return LONG2NUM(lOrbitNumber) ;

}

/* -------------------------------------------------------------------------- */
