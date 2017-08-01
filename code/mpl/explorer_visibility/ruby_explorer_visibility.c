/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER_VISIBILITY CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
# 
#
#########################################################################

*/

#include <ruby.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <libgen.h>
#include <math.h>
#include <time.h>

#include <explorer_visibility.h>
#include <explorer_orbit.h>
#include <explorer_file_handling.h>
#include <explorer_data_handling.h>

/* Defining a space for information 
and references about the module to be stored internally */

static VALUE ruby_explorer_vis   = Qnil ;
static VALUE mpl                 = Qnil ;

/* Prototype for the initialization method - Ruby calls this */

void Init_ruby_explorer_visibility() ;

/* Methods exposed to Ruby by the C extension */

VALUE method_check_library_version() ;
VALUE method_xv_station_vis_time() ;
VALUE method_xv_stationvistime_compute() ;


/* -------------------------------------------------------------------------- */
/* Auxiliary function for closing in case of error                            */
/* -------------------------------------------------------------------------- */

void closeup (long error_code )
{
   char 	error_message [ XF_MAX_ERROR_MSG_LENGTH ] ;
   xf_basic_error_msg ( error_code, error_message ) ;
   printf ( "%s\n", error_message ) ;
   xf_tree_cleanup_all_parser () ;
   exit ( EXIT_FAILURE ) ;
}

/* -------------------------------------------------------------------------- */


/* -------------------------------------------------------------------------- */

void Init_ruby_explorer_visibility()
{
	mpl                  = rb_define_module("MPL") ;
   
   ruby_explorer_vis    = rb_define_class_under(mpl, "Explorer_Visibility", rb_cObject) ;

	rb_define_method(ruby_explorer_vis, "check_library_version", method_check_library_version, 0) ;
   
   rb_define_method(ruby_explorer_vis, "StationVisTimeCompute", method_xv_stationvistime_compute, 8) ;
   
}

/* -------------------------------------------------------------------------- */

/*============================================================================*/
/*  EXPCFI check_library_version direct call          */
/*============================================================================*/

VALUE method_check_library_version() 
{ 
   printf("\n") ;
   printf("DEBUG: Entry ruby_explorer_visibility::method_check_library_version\n") ;  
   printf("\n") ;

   long lValue ;

   lValue = xv_check_library_version() ;
   
   printf("\n") ;
   printf("DEBUG: exit ruby_explorer_visibility::method_check_library_version\n") ;  
   printf("\n") ;
	
   return LONG2NUM(lValue) ;
}

/* -------------------------------------------------------------------------- */


/*============================================================================*/
/*  EXPCFI xv_station_vis_time direct call          */
/*============================================================================*/

VALUE method_xv_stationvistime_compute(
                                          VALUE self, 
                                          VALUE strROEF, 
                                          VALUE strSwath, 
                                          VALUE strStationDB,
                                          VALUE strStation, 
                                          VALUE startOrbit, 
                                          VALUE endOrbit,
                                          VALUE strOutFile,
                                          VALUE isDebugMode
                                          ) 
{

   int iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("\n") ;
      printf("DEBUG: entry ruby_explorer_visibility::method_xv_stationvistime_compute\n") ;  
      printf("\n") ;
   }
   
   /* --------------------------------------------------- */

   /* --------------------------------------------------- */
   /* error handling */
   long status,
       ierr[XO_ERR_VECTOR_MAX_LENGTH],
       n,
       func_id ; /* Error codes vector */
   /* --------------------------------------------------- */
   char msg[XO_MAX_COD][XO_MAX_STR] ; /* Error messages vector */
   /* --------------------------------------------------- */

   long station_err[XV_NUM_ERR_STATION_VIS_TIME] ;
   long xv_ierr[XV_ERR_VECTOR_MAX_LENGTH] ;
   long local_status ;

   char path_orbit_file[XO_MAX_STR] ;   
   strcpy(path_orbit_file, StringValueCStr(strROEF) ) ;

   char swath_file[XV_MAX_STR] ;   
   strcpy(swath_file, StringValueCStr(strSwath)) ;

   /* --------------------------------------------------- */

   char stat_file[XV_MAX_STR] ;
   strcpy (stat_file, StringValueCStr(strStationDB)) ;


   if (iDebug == 1)
   {
      printf("ref orbit   :  %s\n", path_orbit_file) ;
      printf("swath       :  %s\n", swath_file) ;
      printf("station db  :  %s\n", stat_file) ;
   }

   long num_stations ;
   char ** station_list_id ;

   local_status = xd_read_station_id(
                                       stat_file,
                                       &num_stations, 
                                       &station_list_id, 
                                       xv_ierr
                                       ) ;
   if (local_status != XV_OK)
   {
      func_id = XD_READ_STATION_ID ;
      xd_get_msg(&func_id, xv_ierr, &n, msg) ;
      xv_print_msg(&n, msg) ;
   }
   else
   {
   /*
      printf("\n") ;
      printf("xd_read_station_id OK") ;
      printf("\n") ;
   */
   }


   /* --------------------------------------------------- */

   char station_id[XV_MAX_STR] ;
   strcpy(station_id, StringValueCStr(strStation)) ;

   /* --------------------------------------------------- */

   long lAbsStartOrbit  = NUM2ULONG(startOrbit) ;
   long lAbsStopOrbit   = NUM2ULONG(endOrbit) ;
      
   char xmlFile[XV_MAX_STR] ;
   char* outFilename ;
   
   strcpy(xmlFile, StringValueCStr(strOutFile)) ;      
   outFilename = basename(strdup(xmlFile) ) ;
   /* --------------------------------------------------- */
   
   /* --------------------------------------------------- */

   /* ------------------------------------------------------
   
      Read input files real filenames from the fixed header:
      - osf
      - swathvis
      - gnd station db
      ------------------------------------------------------
   */
   
   char * szMission              = NULL ;
   char * szFilenameOSF          = NULL ;
   char * szFilenameSwath        = NULL ;
   char * szFilenameStationDB    = NULL ;

   long fd_1 ;
   char 	path [ XF_MAX_PATH_LENGTH ] ;

   /*
      read orbit scenario file
   */
   
   fd_1 = xf_tree_init_parser ( path_orbit_file, &local_status ) ;

   if ( local_status < XF_CFI_OK )
   {
      printf("\n\nError parsing file %s\n\n", path_orbit_file) ;
      closeup (local_status) ;
   }

   strcpy ( path, "/Earth_Explorer_File/Earth_Explorer_Header/Fixed_Header/Mission" ) ;
   
   
   xf_tree_path_read_string_node_value(
                                          &fd_1, 
                                          path, 
                                          &szMission,
                                          &local_status 
                                          ) ;


   if ( local_status < XF_CFI_OK )
   {
      printf("\nError reading element as string\n" ) ;
      closeup (local_status) ;
   }
   else
   {
      if (iDebug == 1)
      {
         printf("\n%s => %s", path, szMission) ;
      }
   }
  
  
   strcpy ( path, "/Earth_Explorer_File/Earth_Explorer_Header/Fixed_Header/File_Name" ) ;
   
   
   xf_tree_path_read_string_node_value ( 
                                          &fd_1, 
                                          path, 
                                          &szFilenameOSF, 
                                          &local_status 
                                          ) ;


   if ( local_status < XF_CFI_OK )
   {
      printf("\nError reading element as string\n" ) ;
      closeup (local_status) ;
   }
   else
   {
      if (iDebug == 1)
      {
         printf("\n%s => %s", path, szFilenameOSF) ;
      }
   }

   xf_tree_cleanup_parser ( &fd_1, &local_status ) ;


   if ( local_status < XF_CFI_OK )
   {
      printf("\nError closing parser xf_tree_cleanup_parser\n" ) ;
      closeup (local_status) ;
   }

   /*
      read swath file
   */


   fd_1 = xf_tree_init_parser ( swath_file, &local_status ) ;

   if ( local_status < XF_CFI_OK )
   {
      printf("\nError parsing file %s\n", swath_file) ;
      closeup (local_status) ;
   }

   strcpy ( path, "/Earth_Explorer_File/Earth_Explorer_Header/Fixed_Header/File_Name" ) ;
   xf_tree_path_read_string_node_value ( 
                                          &fd_1, 
                                          path, 
                                          &szFilenameSwath, 
                                          &local_status 
                                          ) ;

   if ( local_status < XF_CFI_OK )
   {
      printf("\nError reading element as string\n" ) ;
      closeup (local_status) ;
   }
   else
   {
      if (iDebug == 1)
      {
         printf("\n%s => %s", path, szFilenameSwath) ;
      }
   }

  
   xf_tree_cleanup_parser ( &fd_1, &local_status ) ;

   if ( local_status < XF_CFI_OK )
   {
      printf("\nError closing parser xf_tree_cleanup_parser\n" ) ;
      closeup (local_status) ;
   }
  

   /*
      read ground station database file
   */
  
  
   fd_1 = xf_tree_init_parser ( stat_file, &local_status ) ;

   if ( local_status < XF_CFI_OK )
   {
      printf("\nError parsing file %s\n", stat_file) ;
      closeup (local_status) ;
   }
  
   strcpy ( path, "/Earth_Explorer_File/Earth_Explorer_Header/Fixed_Header/File_Name" ) ;
   xf_tree_path_read_string_node_value ( 
                                          &fd_1, 
                                          path, 
                                          &szFilenameStationDB, 
                                          &local_status 
                                          ) ;

   if ( local_status < XF_CFI_OK )
   {
      printf("\nError reading element as string\n" ) ;
      closeup (local_status) ;
   }
   else
   {
      if (iDebug == 1)
      {
         printf("\n%s => %s", path, szFilenameStationDB) ;
      }
   }


   xf_tree_cleanup_parser ( &fd_1, &local_status ) ;

   if ( local_status < XF_CFI_OK )
   {
      printf("\nError closing parser xf_tree_cleanup_parser\n" ) ;
      closeup (local_status) ;
   }


   /* --------------------------------------------------- */
   /* --------------------------------------------------- */
   
   xl_model_id    model_id    = {NULL} ;
   xl_time_id     time_id     = {NULL} ;
   xo_orbit_id    orbit_id    = {NULL} ;

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
   
   double time0,
         time1,  
         val_time0,
         val_time1 ;

   long time_ref_utc ;
   long i ;   
   double dTimeStart, dTimeStop ;
      
   /* time_model           = XL_TIMEMOD_OSF ; */
   time_model           = XL_TIMEMOD_AUTO ;
   n_files              = 1 ;
   time_init_mode       = XL_SEL_FILE ;
   time_ref_utc         = XL_TIME_UTC ;
   orbit_file[0]        = path_orbit_file ;


   status = xl_time_ref_init_file(  
                                    &time_model, 
                                    &n_files, 
                                    orbit_file,
                                    &time_init_mode, 
                                    &time_ref_utc, 
                                    &dTimeStart, 
                                    &dTimeStop,
                                    &lAbsStartOrbit, 
                                    &lAbsStopOrbit, 
                                    &dTimeStart, 
                                    &dTimeStop, 
                                    &time_id,
                                    ierr
                                    ) ;
                                    
   if (status != XO_OK)
   {
      func_id = XL_TIME_REF_INIT_FILE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }
   else
   {
      /*
      printf("\n") ;
      printf("xl_time_ref_init_file OK") ;
      printf("\n") ;
      */
   }


   /* orbit initialization with an OSF */
   /* -------------------------------- */
      
   sat_id               = XO_SAT_SENTINEL_2A ;   
   n_files              = 1 ;
   time_mode            = XO_SEL_FILE ;
   orbit_mode           = XO_ORBIT_INIT_AUTO ;
  

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
                                 &lAbsStartOrbit, 
                                 &lAbsStopOrbit,
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
      /*
      printf("\n") ;
      printf("xo_orbit_init_file OK") ;
      printf("\n") ;
      */
   }


   xp_attitude_def                 att_def = {XP_NONE_ATTITUDE, {NULL}, {NULL}, {NULL}} ;


   /* =================================================== */

   /* XV_SWATH_ID_INIT */

   /* Variables to call xv_swath_id_init */
   /* ---------------------------------- */
   xv_swath_id                     swath_id = {NULL} ;
   xv_swath_info                   swath_info ;
   xp_atmos_id                     atmos_id    = {NULL} ;


   
   swath_info.sdf_file              = NULL ;
   swath_info.stf_file              = NULL ;
   swath_info.nof_regen_orbits      = 0 ;
   swath_info.filename              = swath_file ;
   swath_info.type                  = XV_FILE_STF ;
   
   /* swath_info.type = XV_FILE_SDF ; */
   /* swath_info.type = XV_FILE_STF ; */


   local_status = xv_swath_id_init(
                                    &swath_info,
                                    &atmos_id,
                                    &swath_id, 
                                    xv_ierr
                                   ) ;
                                   
   if (local_status != XV_OK)
   {
      func_id = XV_SWATH_ID_INIT_ID ; 
      xv_get_msg(&func_id, xv_ierr, &n, msg) ;
      xv_print_msg(&n, msg) ;
   }
   else
   {
      /*
      printf("\n") ;
      printf("xv_swath_id_init OK") ;
      printf("\n") ;
      */
   }

   /* =================================================== */

   /* --------------------- */
   /*   XV_SWATHPOS_COMPUTE */
   /* --------------------- */
   
   xv_time     swathpos_time ;
   xv_swath_point_list swath_point = {0, NULL} ;

   swathpos_time.type         = XV_ORBIT_TYPE ;
   swathpos_time.orbit_type   = XV_ORBIT_ABS ;
   swathpos_time.orbit_num    = lAbsStartOrbit ;
   swathpos_time.sec          = 0 ;
   swathpos_time.msec         = 0 ;

   status = xv_swathpos_compute(
                                 &orbit_id,
                                 &swath_id, 
                                 &swathpos_time,
                                 &swath_point, ierr
                                 ) ;
                                
   if (local_status != XV_OK)
   {
      func_id = XV_SWATHPOS_COMPUTE_ID ;
      xv_get_msg(&func_id, ierr, &n, msg) ;
      xv_print_msg(&n, msg) ;
   }
   else
   {
      /*
      printf("\n") ;
      printf("xv_swathpos_compute OK") ;
      printf("\n") ;
      */
   }
   

   /* print outputs */
   
   /*
   
   printf("\n\nInputs: ");   
   printf("\n   Absolute Orbit: %ld", swathpos_time.orbit_num);   
   printf("\n   ANX Time: %f", swathpos_time.sec+(swathpos_time.msec*1.e-6));
   printf("\nOutputs: ");   
   printf("\n   Swath longitude: %f", swath_point.swath_point[0].lon);   
   printf("\n   Swath latitude: %f", swath_point.swath_point[0].lat);
   printf("\n   Swath altitude: %f", swath_point.swath_point[0].alt);   

   */


   if (swath_point.swath_point != NULL)
   {
     free(swath_point.swath_point);
     swath_point.swath_point = NULL;
   }
   

   /* =================================================== */


   xv_station_info_list               sta_list ;
   xv_stationvisibility_interval_list sta_vis_list = {0, NULL} ;
   
   
   /* Station info list */
  
   /* Extra information such as atmospheric correction is not computed */
   sta_list.calc_flag = XV_DO_NOT_COMPUTE ;
  
   /* ============================================= */
   /* number of records of the ground database file */
   
   sta_list.num_rec = 1 ;
   sta_list.station_info = (xv_station_info*)malloc(sizeof(xv_station_info)) ;
   sta_list.station_info -> type                = XV_USE_STATION_FILE ;
   sta_list.station_info -> station_db_filename = stat_file ;
   sta_list.station_info -> station_id          = station_id ;
   sta_list.station_info -> min_duration        = 0. ;

  
   xv_time_interval  interval ;   
   
   /* Time interval start */
   interval.tstart.type       = XV_ORBIT_TYPE ;
   interval.tstart.orbit_type = XV_ORBIT_ABS ;
   interval.tstart.orbit_num  = lAbsStartOrbit ;
   interval.tstart.sec        = 0 ;
   interval.tstart.msec       = 0 ;
  
   /* Time interval stop */
   interval.tstop.type        = XV_ORBIT_TYPE ;
   interval.tstop.orbit_type  = XV_ORBIT_ABS ;
   interval.tstop.orbit_num   = lAbsStopOrbit ;
   interval.tstop.sec         = 0 ;
   interval.tstop.msec        = 0 ;
    
   local_status = 0 ;

   local_status = xv_stationvistime_compute( 
                                             &orbit_id, 
                                             &att_def,
                                             &swath_id,
                                             &sta_list,
                                             &interval,
                                             &sta_vis_list,
                                             ierr
                                             ) ;
       
   if (local_status != XV_OK)
   {
      func_id = XV_STATIONVISTIME_COMPUTE_ID ;
      xv_get_msg(&func_id, station_err, &n, msg) ;
      xv_print_msg(&n, msg) ;
   }
   else
   {
      /*
      printf("\n") ;
      printf("xv_stationvistime_compute OK") ;
      printf("\n") ;
      */   
   }

   free(sta_list.station_info) ;

   /* create files */

   long fd, error, header_type ; 
   
   
   fd = xf_tree_create(&error) ;

   if ( error < XF_CFI_OK )
   {
      printf("\nError creating XML document\n") ;
      closeup(error) ;
   }

   xf_tree_create_root( &fd, "Earth_Explorer_File", &error) ;
  
   xf_tree_add_child( &fd, ".", "Data_Block", &error) ;
    
   xf_tree_add_child( &fd, ".", "List_Of_Segments", &error) ;
    
   if (iDebug == 1)
   {
      /* print outputs */
      printf("\n\nInputs: ");   
      printf("\n   Start/Stop Absolute Orbit: %ld / %ld", interval.tstart.orbit_num, interval.tstop.orbit_num);   
      printf("\n   Station: %s", station_id);
      printf("\nOutputs: ");   
      printf("\n   Number of segments: %ld", sta_vis_list.num_rec);   
      printf("\n   Segments: Start (Orbit, seconds, microseconds) -- Stop (Orbit, seconds, microseconds) ") ;
   }
   
   char validity_start[32] ;
   char validity_stop[32] ;
   char creation_date[32] ;
   
   int iFirst = 1 ;
    
   for(i=0; i <  sta_vis_list.num_rec; i++)
   {
      if (iDebug == 1)
      {

         printf("\n             (%4d, %4d, %6d) -- (%4d, %4d, %6d) ",
               sta_vis_list.visibility_interval[i].time_interval.tstart.orbit_num,
               sta_vis_list.visibility_interval[i].time_interval.tstart.sec,
               sta_vis_list.visibility_interval[i].time_interval.tstart.msec,
               sta_vis_list.visibility_interval[i].time_interval.tstop.orbit_num,
               sta_vis_list.visibility_interval[i].time_interval.tstop.sec,
               sta_vis_list.visibility_interval[i].time_interval.tstop.msec) ;
            
      }
            long lOrbit, lSec, lMsec ;
            double time_start, time_stop ;

            long lProcessingFormat ;
            long ascii_id_out ;
            char ascii_utc_start[32] ;
            char ascii_utc_stop[32] ;
           
            lOrbit = sta_vis_list.visibility_interval[i].time_interval.tstart.orbit_num ;
            lSec   = sta_vis_list.visibility_interval[i].time_interval.tstart.sec ;    
            lMsec  = sta_vis_list.visibility_interval[i].time_interval.tstart.msec ; 
            
            local_status = xo_orbit_to_time(
                                             &orbit_id,
                                             &lOrbit,
                                             &lSec,
                                             &lMsec, 
                                             &time_ref_utc,
                                             &time_start,
                                             ierr 
                                             ) ;  
  
            if (local_status != XO_OK)
            {
               func_id = XO_ORBIT_TO_TIME_ID ;
               xo_get_msg(&func_id, ierr, &n, msg) ;
               xo_print_msg(&n, msg) ;
            }

            lProcessingFormat    = XL_PROC ;
            time_ref_utc         = XL_TIME_UTC ;
            ascii_id_out         = XL_ASCII_CCSDSA_MICROSEC ;
                        
            local_status = xl_time_processing_to_ascii(  
                                          &time_id,  
                                          &lProcessingFormat,
                                          &time_ref_utc,
                                          &time_start,
                                          &ascii_id_out,
                                          &time_ref_utc,
                                          ascii_utc_start, 
                                          ierr)
                                          ;            

            if (status != XL_OK)
            {
               func_id = XL_TIME_PROCESSING_TO_ASCII_ID ;
               xl_get_msg(&func_id, ierr, &n, msg) ;
               xl_print_msg(&n, msg) ;
            }
            
            lOrbit = sta_vis_list.visibility_interval[i].time_interval.tstop.orbit_num ;
            lSec   = sta_vis_list.visibility_interval[i].time_interval.tstop.sec ;    
            lMsec  = sta_vis_list.visibility_interval[i].time_interval.tstop.msec ; 
            
            local_status = xo_orbit_to_time(
                                             &orbit_id,
                                             &lOrbit,
                                             &lSec,
                                             &lMsec, 
                                             &time_ref_utc,
                                             &time_stop,
                                             ierr 
                                             ) ;  
  
            if (local_status != XO_OK)
            {
               func_id = XO_ORBIT_TO_TIME_ID ;
               xo_get_msg(&func_id, ierr, &n, msg) ;
               xo_print_msg(&n, msg) ;
            }

            lProcessingFormat    = XL_PROC ;
            time_ref_utc         = XL_TIME_UTC ;
            ascii_id_out         = XL_ASCII_CCSDSA_MICROSEC ;
                        
            local_status = xl_time_processing_to_ascii(  
                                          &time_id,  
                                          &lProcessingFormat,
                                          &time_ref_utc,
                                          &time_stop,
                                          &ascii_id_out,
                                          &time_ref_utc,
                                          ascii_utc_stop, 
                                          ierr)
                                          ;            

            if (status != XL_OK)
            {
               func_id = XL_TIME_PROCESSING_TO_ASCII_ID ;
               xl_get_msg(&func_id, ierr, &n, msg) ;
               xl_print_msg(&n, msg) ;
            }
 
            if (iDebug == 1)
            {
               printf("(%s) -- (%s) ", ascii_utc_start, ascii_utc_stop) ;
            }
            /*            
               printf("%s, ", sta_vis_list.visibility_interval[i].station_coverage_info_list.station_coverage_info->station_id) ; 
               printf("\nstation_coverage_info_list.num_rec %ld \n", sta_vis_list.visibility_interval[i].station_coverage_info_list.num_rec) ;
            */
            
            
            
            
      if (i == 0)
      {
         xf_tree_add_child( &fd, ".", "Segment", &error) ;      
      }
      else
      {
         xf_tree_add_child( &fd, "../../..", "Segment", &error) ;     
      }
      
      xf_tree_add_child( &fd, ".", "Start", &error) ;

      xf_tree_add_child( &fd, ".", "UTC", &error) ;
      xf_tree_set_string_node_value( &fd, ".", ascii_utc_start, "%s", &error) ;

      if (iFirst == 1)
      {
         strcpy(validity_start, ascii_utc_start) ;
         iFirst = 0 ;
      }

      /* xf_tree_add_child( &fd, ".", "Orbit", &error) ; */
      xf_tree_add_next_sibling( &fd, ".", "Orbit", &error) ;

      xf_tree_set_string_node_value( &fd, ".", sta_vis_list.visibility_interval[i].time_interval.tstart.orbit_num, "%ld", &error) ;

      xf_tree_add_next_sibling( &fd, ".", "ANX_sec", &error) ;
      xf_tree_set_string_node_value( &fd, ".", sta_vis_list.visibility_interval[i].time_interval.tstart.sec, "%ld", &error) ;
  
      xf_tree_add_next_sibling( &fd, ".", "ANX_msec", &error) ;
      xf_tree_set_string_node_value( &fd, ".", sta_vis_list.visibility_interval[i].time_interval.tstart.msec, "%ld", &error) ;

  
      xf_tree_add_next_sibling( &fd, "..", "Stop", &error) ;
      
      xf_tree_add_child( &fd, ".", "UTC", &error) ;
      xf_tree_set_string_node_value( &fd, ".", ascii_utc_stop, "%s", &error) ;
      strcpy(validity_stop, ascii_utc_stop) ;

      /* xf_tree_add_child( &fd, ".", "Orbit", &error) ; */
      xf_tree_add_next_sibling( &fd, ".", "Orbit", &error) ;

      xf_tree_set_string_node_value( &fd, ".", sta_vis_list.visibility_interval[i].time_interval.tstop.orbit_num, "%ld", &error) ;

      xf_tree_add_next_sibling( &fd, ".", "ANX_sec", &error) ;
      xf_tree_set_string_node_value( &fd, ".", sta_vis_list.visibility_interval[i].time_interval.tstop.sec, "%ld", &error) ;

      xf_tree_add_next_sibling( &fd, ".", "ANX_msec", &error) ;
      xf_tree_set_string_node_value( &fd, ".", sta_vis_list.visibility_interval[i].time_interval.tstop.msec, "%ld", &error) ;
                
   }
  
   if (iDebug == 1)
   {
      printf("\n\n") ;
   }

   header_type = XF_HEADER_FORMAT_EEF ;

   xf_tree_create_header( &fd, &header_type, &error) ;

   if ( error < XF_CFI_OK )
   {
      printf("\nError setting the header document\n") ;
   }

   static char    item_id [XF_MAX_VALUE_LENGTH] ;   /* = "Notes" ; */
   static char    item_value [XF_MAX_VALUE_LENGTH] ; /*= "Value into header" ; */

   strcpy(item_id, "File_Name") ;
   strcpy(item_value, outFilename) ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;

   strcpy(item_id, "Notes") ;
   strcpy(item_value, station_id) ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;
  
   strcpy(item_id, "File_Description") ;
   strcpy(item_value, "ground station visibilities by xv_stationvistime_compute") ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;
 
   strcpy(item_id, "Mission") ;
   strcpy(item_value, szMission) ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;

   strcpy(item_id, "File_Class") ;
   strcpy(item_value, "Routine Operations") ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;

   strcpy(item_id, "File_Type") ;
   strcpy(item_value, "MPL_GNDVIS") ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;

   strcpy(item_id, "File_Version") ;
   strcpy(item_value, "0000") ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;

   strcpy(item_id, "Validity_Start") ;
   strcpy(item_value, validity_start) ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;

   strcpy(item_id, "Validity_Stop") ;
   strcpy(item_value, validity_stop) ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;
 
   strcpy(item_id, "System") ;
   strcpy(item_value, "dec/mpl") ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;

   strcpy(item_id, "Creator") ;
   strcpy(item_value, "xv_stationvistime_compute") ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;
 
   strcpy(item_id, "Creator_Version") ;
   strcpy(item_value, "1.0") ;
   
   /*
   long lValue ;
   lValue = xl_check_library_version() ;
   sprintf(item_value, "%lu", lValue) ;
   */
   
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;
   
   
   time_t timer ; 
   struct tm* tm_info ;
    
   time(&timer) ;
   /* tm_info = localtime(&timer) ; */
   tm_info = gmtime(&timer) ;

   strftime(creation_date, 19, "%Y-%m-%dT%H:%M:%S", tm_info) ;
   /* puts(creation_date) ;   */
   
   strcpy(item_id, "Creation_Date") ;
   strcpy(item_value, creation_date) ;
   xf_tree_set_fixed_header_item( &fd, item_id, item_value, &error) ;
   
   xf_tree_add_child ( &fd, "/Earth_Explorer_File/Earth_Explorer_Header/Variable_Header",
              "Station", &error ) ;
   xf_tree_set_string_node_value ( &fd, ".", station_id, "%s", &error ) ;
   
   xf_tree_add_child ( &fd, "/Earth_Explorer_File/Earth_Explorer_Header/Variable_Header",
              "List_Of_Inputs", &error ) ;
 
   xf_tree_add_child ( &fd, ".", "Input", &error ) ;
   xf_tree_set_string_node_value ( &fd, ".", szFilenameStationDB, "%s", &error ) ;

   xf_tree_add_next_sibling ( &fd, ".", "Input", &error ) ;
   xf_tree_set_string_node_value ( &fd, ".", szFilenameSwath, "%s", &error ) ;

   xf_tree_add_next_sibling ( &fd, ".", "Input", &error ) ;
   xf_tree_set_string_node_value ( &fd, ".", szFilenameOSF, "%s", &error ) ;
    
   xf_tree_write (&fd, xmlFile, &error ) ;  
  
   if ( error < XF_CFI_OK )
   {
      printf("\nError writting XML document\n") ;
      closeup (error) ;
      return -1 ;
   }
 
   xf_tree_cleanup_all_parser() ;

   if (sta_vis_list.visibility_interval != NULL)
   {
      free(sta_vis_list.visibility_interval) ;
      sta_vis_list.visibility_interval = NULL ;
   }
 
   if (iDebug == 1)
   {
      printf("\n") ;
      printf("DEBUG: exit ruby_explorer_visibility::method_xv_stationvistime_compute\n") ;  
      printf("\n") ;
   }
	
   return LONG2NUM(local_status) ;
}


/* -------------------------------------------------------------------------- */

/*============================================================================*/

