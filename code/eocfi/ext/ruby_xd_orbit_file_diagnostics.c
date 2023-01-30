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

#include <explorer_data_handling.h>
#include <explorer_orbit.h>

extern VALUE rbException ;
extern xd_oem_file oem_data ;
static int iDebug ;

/*

typedef struct
  {
    double gap_threshold; // time to identify a gap [s]
    double duplicated_osv_threshold; // time to identify a duplicated OSV [s]
    double time_step; // expected time step [s]
    double time_step_threshold; // time step threshold, to identify non-equally spaced OSVs [s]
    long time_ref; // time system that will be used to fill time related fields in the report structure
  } xd_orbit_file_diagnostics_settings; //AN-576


long xd_orbit_file_diagnostics(char* orbit_file,
                                 xd_eocfi_file* eocfi_file,
                                 xd_orbit_file_diagnostics_settings* diagnostics_settings,
                                 // output
                                 xd_orbit_file_diagnostics_report* diagnostics_report,
                                 long ierr[XD_NUM_ERR_ORBIT_FILE_DIAGNOSTICS]); //AN-576


 typedef struct
  {
    long osv_list_id; //identifier associated to the OSV list (applicable for file storing multiple OSV lists, e.g. SP3)
    long num_osv; //number of OSVs which were checked
    double total_time; //total time covered by the file (i.e. from first to last OSV)
    double time_first_osv; //time of first OSV
    double time_last_osv; //time of last OSV
    long time_ref; //time system of time related fields in this structure
    double* time_start_gap; //list containing start time of GAPs
    double* time_stop_gap; //list containing stop time of GAPs
    long* index_gap; //list containing index of GAPs (the index represents the ID of OSV which is preceded by a GAP)
    long num_gaps; //number of identified GAPs
    double* time_going_back_osv; //list containing time of going back OSVs
    long* index_going_back_osv; //list containing index of going back OSVs
    long num_going_back_osv; //number of identified going back OSVs
    double* time_duplicated_osv; //list containing time of duplicated OSVs
    long* index_duplicated_osv; //list containing index of duplicated OSVs
    long num_duplicated_osv; //number of identified duplicated OSVs
    double* time_inconsistent_orbit_number; //list containing time of OSVs with inconsistent orbit number
    long* index_inconsistent_orbit_number; //list containing index of OSVs with inconsistent orbit number
    long num_inconsistent_orbit_number; //number of OSVs with inconsistent orbit number
    double* time_non_equally_spaced_osv; //list containing time of non equally spaced OSVs
    long* index_non_equally_spaced_osv; //list containing index of non equally spaced OSVs
    long num_non_equally_spaced_osv; //number of OSVs with time step different from expected (absolute value of difference from step and expected > threshold)
  } xd_orbit_file_diagnostics_report_single; //AN-576


typedef struct
  {
    long file_type; //orbit file type: XD_POF_TYPE, XD_ROF_TYPE, XD_DORIS_TYPE, XD_OEM_TYPE, XD_SP3_TYPE
    long osv_list_num; //number of OSV lists processed
    xd_orbit_file_diagnostics_report_single* diagnostics_reports;
  } xd_orbit_file_diagnostics_report; //AN-576


*/


VALUE method_xd_orbit_file_diagnostics(
                              VALUE self,
                              VALUE orbit_file_,
                              VALUE eocfi_file_,
                              VALUE diagnostics_settings_,
                              VALUE isDebugMode
                           ) 
{

   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xd_orbit_file_diagnostics\n") ;
   }

   char path_orbit_file[XD_MAX_STR] ;
   strcpy (path_orbit_file, StringValueCStr(orbit_file_)) ;

   /* --------------------------------------------------- */
   /* Error handling for orbit ephemeris presence */
   FILE *file;
   if ((file = fopen(path_orbit_file, "r")))
   {
      if (iDebug == 1)
         printf("DEBUG: method_xd_orbit_file_diagnostics file %s is available\n", path_orbit_file) ;

      fclose(file) ;
   }
   else
   {
      if (iDebug == 1)
         printf("DEBUG: method_xd_orbit_file_diagnostics file %s not found\n", path_orbit_file) ;

      rb_raise(rbException, "method_xd_orbit_file_diagnostics file %s not found", path_orbit_file) ;

   }

   xd_eocfi_file some_eocfi_file ;

   some_eocfi_file.file_type = XD_OEM_FILE ;
   some_eocfi_file.eocfi_file.oem_file = oem_data ;

   xd_orbit_file_diagnostics_settings diagnostics_settings ;

   /* 30 seconds */
   diagnostics_settings.gap_threshold              = 30 ;
   diagnostics_settings.duplicated_osv_threshold   = 30 ;
   diagnostics_settings.time_step                  = 30 ;
   diagnostics_settings.time_step_threshold        = 30 ;
   diagnostics_settings.time_ref                   = XD_TIME_UTC ;

   xd_orbit_file_diagnostics_report diagnostics_report ;

   /* --------------------------------------------------- */
   /* error handling */
   long status,
       ierr[XO_NUM_ERR_ORBIT_ID_CHECK],
       n,
       func_id ; /* Error codes vector */
   
   /* --------------------------------------------------- */
   /* Error messages vector */
   char msg[XD_MAX_COD][XD_MAX_STR] ; 
   /* --------------------------------------------------- */
   
   status = xd_orbit_file_diagnostics(    &path_orbit_file,
                                          &some_eocfi_file,
                                          &diagnostics_settings,
                                          &diagnostics_report,
                                          ierr) ;
   

   if (iDebug == 1)
   {
      printf("DEBUG: method_xd_orbit_file_diagnostics xd_orbit_file_diagnostics status: %ld ierr: %li\n", status, *ierr) ;
   }
                                 
   if (status != XD_OK)
   {
      func_id = XD_ORBIT_FILE_DIAGNOSTICS_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xo_print_msg(&n, msg) ;
   }

   printf("DEBUG: %ld\n", diagnostics_report.osv_list_num) ;
   printf("DEBUG: %ld\n", diagnostics_report.diagnostics_reports->num_osv) ;

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xd_orbit_file_diagnostics\n") ;  
   }

   return LONG2NUM(status) ;

}

/* -------------------------------------------------------------------------- */
