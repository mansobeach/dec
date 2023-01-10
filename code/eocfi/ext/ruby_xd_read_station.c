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

#include <explorer_data_handling.h>

/*============================================================================*/
/*  EXPCFI xv_station_vis_time direct call          */
/*============================================================================*/

static xd_station_rec station_rec ;
static int iDebug ;
extern VALUE rbException ;

/*

  typedef struct
  {
    char station_id[XD_MAX_STR];
    char descriptor[XD_MAX_STR];
    char antenna[XD_MAX_STR];
    char purpose[XD_MAX_STR];
    char type[XD_MAX_STR];
    long num_mask_pt;
    double azimuth[XD_VERTICES];
    double elevation[XD_VERTICES];
    double station_long;
    double station_lat;
    double station_alt;
    double proj_long[XD_VERTICES];
    double proj_lat[XD_VERTICES];
    long points;
    double long_max; 
    double lat_max; 
    double long_min; 
    double lat_min; 
    long mission_list;
    char mission_name[XD_MISSIONS][XD_MAX_STR];
    double mis_aos_el[XD_MISSIONS];
    double mis_los_el[XD_MISSIONS];
    char mask_type[XD_MISSIONS][XD_MAX_STR];
  } xd_station_rec;


*/


VALUE method_xd_read_station(
                                          VALUE self,
                                          VALUE strStationDB,
                                          VALUE strStationID,
                                          VALUE isDebugMode
                                          ) 
{
 
   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_method_xd_read_station::method_xd_read_station\n") ;  
   }
   
   /* --------------------------------------------------- */
   /* error handling */
   long n,
   func_id ; /* Error codes vector */
   
   /* --------------------------------------------------- */
   char msg[XD_MAX_COD][XD_MAX_STR] ; /* Error messages vector */
   /* --------------------------------------------------- */

   long xd_ierr[XD_ERR_VECTOR_MAX_LENGTH] ;
   long status ;

   /* --------------------------------------------------- */

   char station_file[XD_MAX_STR] ;
   char station_id[XD_MAX_STR] ;
   strcpy (station_file, StringValueCStr(strStationDB)) ;
   strcpy (station_id, StringValueCStr(strStationID)) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ruby_method_xd_read_station station_file: %s\n", station_file) ;  
   }

   /* --------------------------------------------------- */
   
   status = xd_read_station(
                                       station_file,
                                       station_id, 
                                       &station_rec, 
                                       xd_ierr
                                       ) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xd_read_station xd_read_station status: %ld ierr: %li\n", status, *xd_ierr) ;  
   }

   if (status != XD_OK)
   {
      func_id = XD_READ_STATION_ID ;
      xd_get_msg(&func_id, xd_ierr, &n, msg) ;
      xd_print_msg(&n, msg) ;

      /* raise exception */
      rb_raise(rbException, "ruby_method_xd_read_station file failed") ;

   }
   else
   {
      if (iDebug == 1)
      {
         printf("xd_read_station OK") ;
         printf("\n") ;
         printf("station[%s] => %s ; %s\n", station_rec.station_id, station_rec.descriptor, station_rec.purpose) ;
      }
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT ruby_method_xd_read_station::method_xd_read_station\n") ;
   }
   
   return Data_Wrap_Struct(RBASIC(self)->klass, NULL, NULL, &station_rec) ;

   /*
      
   return TypedData_Wrap_Struct(RBASIC(self)->klass, NULL, &station_rec) ;
   TypedData_Wrap_Struct(RBASIC(self)->klass, data_type, &station_rec) ;  
   return Data_Wrap_Struct(RBASIC(self)->klass, 0, free, &station_rec) ;
   
   */
      
}


/* -------------------------------------------------------------------------- */

/* Mapping of the struct xd_station_rec */

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_antenna(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return rb_str_new2(p->antenna) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_purpose(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return rb_str_new2(p->purpose) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_descriptor(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return rb_str_new2(p->descriptor) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_station_id(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return rb_str_new2(p->station_id) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_type(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return rb_str_new2(p->type) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_mission_name(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return rb_str_new2(p->mission_name) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_station_long(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return DBL2NUM(p->station_long) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_station_lat(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return DBL2NUM(p->station_lat) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_station_alt(VALUE self) 
{
   xd_station_rec* p ;
   Data_Get_Struct(self, xd_station_rec, p) ;
   return DBL2NUM(p->station_alt) ;
}

/* -------------------------------------------------------------------------- */
