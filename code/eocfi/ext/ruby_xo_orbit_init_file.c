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

extern xl_time_id time_id ;
static int iDebug ;
xo_orbit_id    orbit_id    = {NULL} ;

VALUE method_xo_orbit_init_file( VALUE self,
                                    VALUE sat_id_,
                                    VALUE model_id_,
                                    VALUE time_id_,
                                    VALUE orbit_file_mode_,
                                    VALUE n_files_,
                                    VALUE input_files_,
                                    VALUE time_init_mode_,
                                    VALUE time_ref_,
                                    VALUE time0_,
                                    VALUE time1_,
                                    VALUE orbit0_,
                                    VALUE orbit1_,
                                    VALUE isDebugMode
                                    ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xo_orbit_init_file\n") ;
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

   /* orbit initilization */
   /* ------------------- */
   long  sat_id,
         orbit_file_mode,
         n_files, 
         time_init_mode,
         time_ref,
         orbit0,
         orbit1 ;

   /* inputs*/
   double time0, time1 ;
   /* --------------------------------------------------- */
   /* xo_orbit_init_file outputs */
   double val_time0, val_time1 ;
   long lOrbitStart, lOrbitStop ;
   /* --------------------------------------------------- */
   char path_orbit_file[XO_MAX_STR] ;
   char *orbit_file[1] ;

   n_files     = RARRAY_LEN(input_files_) ;

   if (n_files > 1)
   {
      rb_fatal("ERROR: method_xo_orbit_init_file => n_files supported cannot be > 1") ;
   }

   if (n_files != NUM2LONG(n_files_))
   {
      rb_warn("ERROR: method_xo_orbit_init_file => inconsistency between n_files & input_files_ parameters") ;
      n_files     = NUM2LONG(n_files_) ;
   }

   sat_id            = NUM2LONG(sat_id_) ;
   orbit_file_mode   = NUM2LONG(orbit_file_mode_) ;
   time_init_mode    = NUM2LONG(time_init_mode_) ;
   time_ref          = NUM2LONG(time_ref_) ;

   /* ------------------ */
   /* optional parameters */
   if ( RB_FLOAT_TYPE_P(time0_) )
     time0 = NUM2DBL(time0_) ;

   if ( RB_FLOAT_TYPE_P(time1_) )
     time1 = NUM2DBL(time1_) ;
  
   if (TYPE(orbit0_) == T_FIXNUM)
      lOrbitStart = NUM2LONG(orbit0_) ;

   if (TYPE(orbit1_) == T_FIXNUM)
      lOrbitStop = NUM2LONG(orbit1_) ;   
   /* ------------------ */   

   for(int idx =0 ; idx < n_files; idx++)
   {
      VALUE entry = rb_ary_entry(input_files_, idx) ;
      char * c_str = StringValueCStr(entry) ;
      strcpy(path_orbit_file, c_str ) ;
   }

   orbit_file[0]        = path_orbit_file ;

   /* --------------------------------------------------- */
   /* Error handling for orbit ephemeris presence */
   FILE *file;
   if ((file = fopen(path_orbit_file, "r")))
   {
      fclose(file) ;
   }
   else
   {
      rb_fatal("ERROR: method_xo_orbit_init_file => cannot open file %s", path_orbit_file) ; 
   }

   xl_model_id    model_id    = {NULL} ;
   
   /* --------------------------------------------------- */


   /* orbit initialization with an OSF */
   /* -------------------------------- */
  
   status = xo_orbit_init_file(  &sat_id,             // XO_SAT_SENTINEL_2A
                                 &model_id,           // NULL 
                                 &time_id,            // NULL
                                 &orbit_file_mode,    // XO_ORBIT_INIT_AUTO
                                 &n_files,            // 1
                                 orbit_file,          // Array of one OSF
                                 &time_init_mode,     // XO_SEL_FILE
                                 &time_ref,           // XL_TIME_UTC
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
      printf("DEBUG: method_xo_orbit_init_file xo_orbit_init_file status: %ld ierr: %li\n", status, *ierr) ;  
   }
                                 
   if (status != XO_OK)
   {
      func_id = XO_ORBIT_INIT_FILE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }

   /* --------------------------- */
   /* Free Memory */
   /* --------------------------- */
   
   /* 
   xo_orbit_close (&orbit_id, ierr) ;
   */

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xo_orbit_init_file\n") ;  
   }

   return Data_Wrap_Struct(RBASIC(self)->klass, NULL, NULL, &orbit_id) ;

}

/* -------------------------------------------------------------------------- */
