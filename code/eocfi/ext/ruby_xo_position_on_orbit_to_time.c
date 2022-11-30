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


VALUE method_xo_position_on_orbit_to_time(VALUE self, VALUE strROEF, VALUE lOrbit, VALUE dAngle, VALUE isDebugMode) 
{
/*
   printf("\n") ;
   printf("DEBUG: entry ruby_earth_explorer_cfi::method_PositionInOrbit\n") ;  
   printf("\n") ;
*/ 

   int iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_xo_position_on_orbit_to_time::method_xo_position_on_orbit_to_time\n") ;  
   }
   
   
   char path_orbit_file[XO_MAX_STR] ;   
   strcpy(path_orbit_file, StringValueCStr(strROEF) ) ;

   long lOrbitNumber = NUM2ULONG(lOrbit) ;

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
   printf("DEBUG: entry ruby_earth_explorer_cfi::method_PositionInOrbit \n" ) ;
   printf("OSF/POF   => %s\n", path_orbit_file) ;
   printf("Orbit     => %li\n", lOrbitNumber) ;
   printf("Angle     => %f\n", NUM2DBL(dAngle) ) ;
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
   /* --------------------------------------------------- */
   /* xl_time_ref_init_file */
   
   long   time_model, n_files, time_init_mode ;
   char   *orbit_file[1] ;
   
   long lOrbitStart, lOrbitStop ;

   double time0,
         time1,  
         val_time0,
         val_time1 ;


   long time_ref_utc ;
   
   double dTimeStart, dTimeStop ;
   
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
                                    ierr) ;
                                    
   if (status != XO_OK)
   {
      func_id = XL_TIME_REF_INIT_FILE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }

   
   long propag_model ;  
   

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
                                 orbit_file,           // Array of one OSF
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
   else
   {
      if (iDebug == 1)
      {
         printf("\n\nxo_orbit_init_file OK !!!\n") ;
      }
   }
  
   /* ============================================ */
   
   /* Check the orbit initialisation */
   
   xd_orbit_file_diagnostics_settings diag_settings ;
   
   xo_orbit_id_check_report report ;   
   
   status = xo_orbit_id_check(&orbit_id, &diag_settings, &report, ierr) ;

   if (status != XO_OK)
   {
      func_id = XO_ORBIT_ID_CHECK_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }
   else
   {
      if (iDebug == 1)
      {
         printf("\n") ;
         printf("check of xo_orbit_init_file OK") ;
         printf("\n") ;
      }
   }
      
   /* ============================================ */
  
  
  
  
     /* Variables for xo_position_on_orbit_to_time */
   long abs_orbit_number,
        angle_type,
        deriv;
   double angle,
          angle_rate,
          angle_rate_rate ;

   double time ;
   
   double pos[3] ;
   double vel[3] ;
   double acc[3] ;

   abs_orbit_number = lOrbitNumber ;
   angle            = NUM2DBL(dAngle) ;
   angle_type       = XL_ANGLE_TYPE_TRUE_LAT_TOD ;
   angle_rate       = 0.059176 ;
   angle_rate_rate  = 0.000000 ;
   deriv            = XL_DER_2ND ;
    
   /* xo_position_on_orbit_to_time */
   propag_model     = XO_PROPAG_MODEL_MEAN_KEPL;
  
   status = xo_position_on_orbit_to_time(  
                                          &orbit_id, 
                                          &abs_orbit_number, 
                                          &angle_type,         // XL_ANGLE_TYPE_TRUE_LAT_TOD
                                          &angle,              // Angle describing the position in the orbit
                                          &angle_rate,         // 1st derivate from Angle
                                          &angle_rate_rate,    // 2nd derivate from Angle
                                          &deriv, 
                                          &time_ref_utc,
                                          /* output */
                                          &time,
                                          pos,
                                          vel, 
                                          acc,
                                          ierr) ;
   if (status != XO_OK)
   {
      func_id = XO_POSITION_ON_ORBIT_TO_TIME_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }
   /*
   else
   {
      printf("\n\nxo_position_on_orbit_to_time OK !!!\n") ;
   }
   */
   
   /*
   
   int j ;
   
   fprintf(stdout, "\n\t-   Orbit          = %li", abs_orbit_number) ;
   fprintf(stdout, "\n\t-   Position       = {");
  
   fprintf(stdout, "\n\t-   Time           = %f", time);
   fprintf(stdout, "\n\t-   Position       = {");
   
   for (j = 0; j < 3; j++)
     fprintf(stdout, "%f, ", pos[j]);
   fprintf(stdout, "}");
  
   fprintf(stdout, "\n\t-   Velocity       = {");
   for (j = 0; j < 3; j++)
     fprintf(stdout, "%f, ", vel[j]);
   fprintf(stdout, "}");

   fprintf(stdout, "\n\t-   Acceleration   = {");
   for (j = 0; j < 3; j++)
     fprintf(stdout, "%f, ", acc[j]);
   fprintf(stdout, "}");

   fprintf(stdout, "\n") ;

   */


   long lProcessingFormat ;
   long ascii_id_out ;
   char ascii_out[32] ;

   /* Call xl_time_processing_to_ascii function */
   /* ----------------------------------------- */

   lProcessingFormat    = XL_PROC ;
   time_ref_utc         = XL_TIME_UTC ;
   /* ascii_id_out         = XL_ASCII_STD_REF_MICROSEC ; */
   ascii_id_out         = XL_ASCII_CCSDSA_MICROSEC ;

   status = xl_time_processing_to_ascii(  
                                          &time_id,  
                                          &lProcessingFormat,     // XL_PROC
                                          &time_ref_utc,          // XL_TIME_UTC
                                          &time,                  // Result of previous xo_position_on_orbit_to_time
                                          &ascii_id_out,          // XL_ASCII_CCSDSA_MICROSEC
                                          &time_ref_utc,          // XL_TIME_UTC
                                          ascii_out, 
                                          ierr)
                                          ;

  /* Print output values */
  /* ------------------- */

  if (status != XL_OK)
  {
     func_id = XL_TIME_PROCESSING_TO_ASCII_ID ;
     xl_get_msg(&func_id, ierr, &n, msg) ;
     xl_print_msg(&n, msg) ;
     if (status <= XL_ERR) return(XL_ERR) ;    /* CAREFUL: normal status */
  }
  /*
  else
  {
      printf("\n\nxl_time_processing_to_ascii OK !!!\n") ;
  }
   */
   

  /* printf("\n- ascii_out        : %s ",     ascii_out) ;   */

  status = xo_orbit_close(&orbit_id, ierr) ;
  
  if (status != XL_OK)
  {
     func_id = XO_ORBIT_CLOSE_ID ;
     xo_get_msg(&func_id, ierr, &n, msg) ;
     xo_print_msg(&n, msg) ;
  }

  if (iDebug == 1)
  {
     printf("DEBUG: EXIT ruby_xo_position_on_orbit_to_time::method_xo_position_on_orbit_to_time\n") ;  
  }

  return rb_str_new2(ascii_out) ;
}


/* -------------------------------------------------------------------------- */


/* -------------------------------------------------------------------------- */
