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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#include <explorer_orbit.h>



/* Defining a space for information 
and references about the module to be stored internally */

static VALUE ruby_explorer_orbit = Qnil ;
static VALUE mpl                 = Qnil ;



/* Prototype for the initialization method - Ruby calls this, not you */

void Init_ruby_explorer_orbit() ;

/* Methods exposed to Ruby by the C extension */

VALUE method_xo_check_library_version() ;
VALUE method_DateTime2OrbitAbsolute() ;
VALUE method_PositionInOrbit() ;

/* -------------------------------------------------------------------------- */

void Init_ruby_explorer_orbit()
{
	mpl                  = rb_define_module("MPL") ;
   
   ruby_explorer_orbit  = rb_define_class_under(mpl, "Explorer_Orbit", rb_cObject) ;

	rb_define_method(ruby_explorer_orbit, "xo_check_library_version", method_xo_check_library_version, 0) ;
   
   rb_define_method(ruby_explorer_orbit, "DateTime2OrbitAbsolute", method_DateTime2OrbitAbsolute, 2) ;

   rb_define_method(ruby_explorer_orbit, "PositionInOrbit", method_PositionInOrbit, 4) ;

}

/* -------------------------------------------------------------------------- */

/*============================================================================*/
/*  EXPCFI check_library_version direct call          */
/*============================================================================*/


VALUE method_xo_check_library_version() 
{
   long lValue = xo_check_library_version() ;   
   printf("\n") ;
   printf("DEBUG: entry ruby_explorer_orbit::method_xo_check_library_version (%li)", lValue) ;
   printf("\n") ;
	return LONG2NUM(lValue) ;
}


/* -------------------------------------------------------------------------- */

/*============================================================================*/
/*  MPL::blah blah blah blah 
      - blah blah blah
      - blah blah blah         */
/*============================================================================*/


VALUE method_PositionInOrbit(VALUE self, VALUE strROEF, VALUE lOrbit, VALUE dAngle) 
{


/*
   char strUTCDate [30] ;
   strcpy(strUTCDate, StringValueCStr(strUTC) ) ; 
*/
   
   char path_orbit_scenario_file[XO_MAX_STR] ;   
   strcpy(path_orbit_scenario_file, StringValueCStr(strROEF) ) ;

  
   printf("\n") ;
   printf("DEBUG: entry ruby_explorer_orbit::method_PositionInOrbit \n" ) ;
   printf("OSF/POF   => %s\n", path_orbit_scenario_file) ;
   printf("Date      => %f\n", dAngle) ;
   printf("\n") ;
   
   
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
   /* char* files[1] ; */
   long sat_id ;
   long propag_model  ;
   /* --------------------------------------------------- */
   /* --------------------------------------------------- */
   /* xo_time_to_orbit & xo_orbit_to_time variables */
   long second_t, microsec_t ; 
   /* --------------------------------------------------- */
   /* xl_time_ref_init_file */
   
   long   time_model, n_files, time_init_mode ;
   char   *time_file[1] ;
   
   long lOrbitNumber, lOrbitStart, lOrbitStop ;

   double time0,
         time1,  
         val_time0,
         val_time1 ;

   long ascii_id_in, lProcessingFormat ;

   long time_ref_utc ;
   
   double dTimeProcessing, dTimeStart, dTimeStop ;
   
   propag_model         = XO_PROPAG_MODEL_MEAN_KEPL ;
   sat_id               = XO_SAT_SENTINEL_2A ;   
   
   /* to be parametrised */
   lOrbitStart          = 9828 ;
   lOrbitStop           = 9830 ;
   
   dTimeStart           = -18260.0 ;
   dTimeStop            = 36523.0 ;
   
   // time_model           = XL_TIMEMOD_OSF ;
   
   time_model           = XL_TIMEMOD_FOS_PREDICTED ;
   
   n_files              = 1 ;
   
   time_init_mode       = XL_SEL_FILE ;
   // time_init_mode       = XL_SEL_ORBIT ;
   
   
   time_ref_utc         = XL_TIME_UTC ;
   time_file[0]         = path_orbit_scenario_file ;
   
   
   status = xl_time_ref_init_file(  &time_model, 
                                    &n_files, 
                                    time_file,
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
   
   

   /* orbit initialization with an OSF */
   /* -------------------------------- */
   n_files    = 1 ;
   time_mode  = XO_SEL_FILE ;
   orbit_mode = XO_ORBIT_INIT_OSF_MODE ;
  

   status = xo_orbit_init_file(  &sat_id,             // XO_SAT_SENTINEL_2A
                                 &model_id,           // NULL 
                                 &time_id,            // NULL
                                 &orbit_mode,         // XO_ORBIT_INIT_OSF_MODE
                                 &n_files,            // 1
                                 time_file,           // Array of one OSF
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
      printf("\n\nxo_orbit_init_file OK !!!\n") ;
   }

  
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

  
  
  abs_orbit_number = 1001;
  angle_type       = XL_ANGLE_TYPE_TRUE_LAT_TOD;
  angle            = 13.961817;
  angle_rate       = 0.059176;
  angle_rate_rate  = 0.000000;
  deriv            = XL_DER_2ND;
    
  /* xo_position_on_orbit_to_time */
  propag_model = XO_PROPAG_MODEL_MEAN_KEPL;
  
  status = xo_position_on_orbit_to_time(&orbit_id, &abs_orbit_number, &angle_type,
                                        &angle, &angle_rate, &angle_rate_rate,
                                        &deriv, &time_ref_utc,
                                        /* output */
                                        &time, pos, vel, acc,
                                        ierr);
  if (status != XO_OK)
  {
    func_id = XO_POSITION_ON_ORBIT_TO_TIME_ID;
    xo_get_msg(&func_id, ierr, &n, msg);
    xo_print_msg(&n, msg);
  }
  
  int j ;
  
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

   status = xo_orbit_close(&orbit_id, ierr) ;
  
  if (status != XL_OK)
  {
     func_id = XO_ORBIT_CLOSE_ID ;
     xo_get_msg(&func_id, ierr, &n, msg) ;
     xo_print_msg(&n, msg) ;
  }





   return LONG2NUM(0) ;
}


















/* -------------------------------------------------------------------------- */

/*============================================================================*/
/*  MPL::DateTime2OrbitAbsolute 
      - full_path_OSF
      - UTC date in format 20201220T120000 (XL_ASCII_CCSDSA_COMPACT)         */
/*============================================================================*/


VALUE method_DateTime2OrbitAbsolute(VALUE self, VALUE strROEF, VALUE strUTC) 
{

   char strUTCDate [30] ;
   strcpy(strUTCDate, StringValueCStr(strUTC) ) ; 
   
   char path_orbit_scenario_file[XO_MAX_STR] ;   
   strcpy(path_orbit_scenario_file, StringValueCStr(strROEF) ) ;

   
   printf("\n") ;
   printf("DEBUG: entry ruby_explorer_orbit::method_DateTime2OrbitAbsolute \n" ) ;
   printf("OSF/POF   => %s\n", path_orbit_scenario_file) ;
   printf("Date      => %s\n", strUTCDate) ;
   printf("\n") ;
   
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
   char* files[1] ;
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
   orbit_file[0]        = path_orbit_scenario_file ;


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
   /* orbit_mode = XO_ORBIT_INIT_OSF_MODE ; */
   orbit_mode = XO_ORBIT_INIT_AUTO ;
   

   status = xo_orbit_init_file(  &sat_id,             // XO_SAT_SENTINEL_2A
                                 &model_id,           // NULL 
                                 &time_id,            // NULL
                                 &orbit_mode,         // XO_ORBIT_INIT_OSF_MODE
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
   
   return LONG2NUM(lOrbitNumber) ;

}

/* -------------------------------------------------------------------------- */
