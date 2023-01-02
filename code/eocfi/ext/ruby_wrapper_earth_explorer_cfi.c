/**
    
#########################################################################
#
# === Wrapper for Ruby to EARTH EXPLORER CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach / Manso Beach
# 
#########################################################################

https://silverhammermba.github.io/emberb/c/

*/

#include <ruby.h>

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#include <explorer_orbit.h>
#include <explorer_data_handling.h>
#include <explorer_file_handling.h>
#include <explorer_visibility.h>

/* Defining a space for information 
and references about the module to be stored internally */
static VALUE ruby_earth_explorer_cfi   = Qnil ;
static VALUE eocfi                     = Qnil ;

VALUE rbException ;

/* Prototype for the initialization method - Ruby calls this, not you */
void Init_ruby_earth_explorer_cfi() ;

/* Prototype for other user functions */
void Init_Ruby_Exception() ;

/* ========================================================= */
/*                                                           */
/* Methods exposed to Ruby by the C extension */
/*                                                           */

VALUE method_xo_check_library_version() ;

VALUE method_xl_time_ref_init_file() ;
VALUE method_xl_time_ascii_to_processing() ;
VALUE method_xl_time_close() ;

VALUE method_xo_orbit_init_file() ;
VALUE method_xo_orbit_id_check() ;
VALUE method_xo_orbit_info() ;
VALUE method_xo_position_on_orbit_to_time() ;
VALUE method_xo_time_to_orbit2() ;
VALUE method_xo_osv_compute() ;
VALUE method_xo_osv_compute_extra() ;

VALUE method_xd_read_station_file() ;
   VALUE method_xd_read_station_file_num_rec() ;
   VALUE method_xd_read_station_file_xd_station_rec() ;

VALUE method_xd_free_station_file() ;

VALUE method_xd_read_station_id() ;

VALUE method_xd_read_tle() ;
   /* number of TLE records */
   VALUE method_xd_read_tle_file_num_rec() ;
   /* line zero */
   VALUE method_xd_read_tle_rec_norad_satcat() ;
   /* first line */
   VALUE method_xd_read_tle_rec_sat_number() ;
   VALUE method_xd_read_tle_rec_classification() ;
   VALUE method_xd_read_tle_rec_time() ;
   VALUE method_xd_read_tle_rec_1st_mean_motion() ;
   VALUE method_xd_read_tle_rec_2nd_mean_motion() ;
   VALUE method_xd_read_tle_rec_bstar() ;
   VALUE method_xd_read_tle_rec_ephemeris_type() ;
   VALUE method_xd_read_tle_rec_element_number() ;
   VALUE method_xd_read_tle_rec_checksum1() ;
   /* second line */
   VALUE method_xd_read_tle_rec_int_des() ;
   VALUE method_xd_read_tle_rec_inclination() ;
   VALUE method_xd_read_tle_rec_eccentricity() ;
   VALUE method_xd_read_tle_rec_w() ;
   VALUE method_xd_read_tle_rec_RAAN() ;
   VALUE method_xd_read_tle_rec_mean_anomaly() ;
   VALUE method_xd_read_tle_rec_mean_motion() ;
   VALUE method_xd_read_tle_rec_abs_orbit() ;
   VALUE method_xd_read_tle_rec_checksum2() ;

VALUE method_xd_read_station() ;
   VALUE method_xd_read_station_station_id() ;
   VALUE method_xd_read_station_descriptor() ;
   VALUE method_xd_read_station_antenna() ;
   VALUE method_xd_read_station_purpose() ;
   VALUE method_xd_read_station_type() ;
   VALUE method_xd_read_station_station_alt() ;
   VALUE method_xd_read_station_station_lat() ;
   VALUE method_xd_read_station_station_long() ;
   VALUE method_xd_read_station_mission_name() ;

VALUE method_xv_swath_id_init() ;

VALUE method_xv_stationvistime_compute() ;


/* ========================================================= */

/* -------------------------------------------------------------------------- */

void Init_ruby_earth_explorer_cfi()
{
	eocfi                      = rb_define_module("EOCFI") ;
   ruby_earth_explorer_cfi    = rb_define_class_under(eocfi, "Earth_Explorer_CFI", rb_cObject) ;

	rb_define_method(ruby_earth_explorer_cfi, "xo_check_library_version", method_xo_check_library_version, 1) ;
   
   rb_define_method(ruby_earth_explorer_cfi, "xl_time_ref_init_file", method_xl_time_ref_init_file, 11) ;
   rb_define_method(ruby_earth_explorer_cfi, "xl_time_ascii_to_processing", method_xl_time_ascii_to_processing, 7) ;
   rb_define_method(ruby_earth_explorer_cfi, "xl_time_close", method_xl_time_close, 1) ;

   rb_define_method(ruby_earth_explorer_cfi, "xo_orbit_init_file", method_xo_orbit_init_file, 13) ;
   rb_define_method(ruby_earth_explorer_cfi, "xo_orbit_id_check", method_xo_orbit_id_check, 2) ;
   rb_define_method(ruby_earth_explorer_cfi, "xo_orbit_info", method_xo_orbit_info, 3) ;
   rb_define_method(ruby_earth_explorer_cfi, "xo_position_on_orbit_to_time", method_xo_position_on_orbit_to_time, 4) ;
   rb_define_method(ruby_earth_explorer_cfi, "xo_time_to_orbit2", method_xo_time_to_orbit2, 3) ;
   rb_define_method(ruby_earth_explorer_cfi, "xo_osv_compute", method_xo_osv_compute, 5) ;
   rb_define_method(ruby_earth_explorer_cfi, "xo_osv_compute_extra", method_xo_osv_compute_extra, 3) ;
   
   rb_define_method(ruby_earth_explorer_cfi, "xd_read_station_file", method_xd_read_station_file, 2) ;
      rb_define_method(ruby_earth_explorer_cfi, "num_rec", method_xd_read_station_file_num_rec, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_station_rec", method_xd_read_station_file_xd_station_rec, 0) ;

   rb_define_method(ruby_earth_explorer_cfi, "xd_free_station_file", method_xd_free_station_file, 2) ;

   rb_define_method(ruby_earth_explorer_cfi, "xd_read_station_id", method_xd_read_station_id, 2) ;

   rb_define_method(ruby_earth_explorer_cfi, "xd_read_station", method_xd_read_station, 3) ;
      rb_define_method(ruby_earth_explorer_cfi, "station_id", method_xd_read_station_station_id, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "descriptor", method_xd_read_station_descriptor, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "antenna", method_xd_read_station_antenna, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "purpose", method_xd_read_station_purpose, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "type", method_xd_read_station_type, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "station_alt", method_xd_read_station_station_alt, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "station_lat", method_xd_read_station_station_lat, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "station_long", method_xd_read_station_station_long, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "mission_name", method_xd_read_station_mission_name, 0) ;

   rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle", method_xd_read_tle, 3) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_file_num_rec", method_xd_read_tle_file_num_rec, 0) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_norad_satcat", method_xd_read_tle_rec_norad_satcat, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_sat_number", method_xd_read_tle_rec_sat_number, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_classification", method_xd_read_tle_rec_classification, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_time", method_xd_read_tle_rec_time, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_bstar", method_xd_read_tle_rec_bstar, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_ephemeris_type", method_xd_read_tle_rec_ephemeris_type, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_element_number", method_xd_read_tle_rec_element_number, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_int_des", method_xd_read_tle_rec_int_des, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_inclination", method_xd_read_tle_rec_inclination, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_RAAN", method_xd_read_tle_rec_RAAN, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_eccentricity", method_xd_read_tle_rec_eccentricity, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_w", method_xd_read_tle_rec_w, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_mean_anomaly", method_xd_read_tle_rec_mean_anomaly, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_mean_motion", method_xd_read_tle_rec_mean_motion, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_abs_orbit", method_xd_read_tle_rec_abs_orbit, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_1st_mean_motion", method_xd_read_tle_rec_1st_mean_motion, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_2nd_mean_motion", method_xd_read_tle_rec_2nd_mean_motion, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_checksum1", method_xd_read_tle_rec_checksum1, 1) ;
      rb_define_method(ruby_earth_explorer_cfi, "xd_read_tle_rec_checksum2", method_xd_read_tle_rec_checksum2, 1) ;

   rb_define_method(ruby_earth_explorer_cfi, "xv_swath_id_init", method_xv_swath_id_init, 1) ;

   rb_define_method(ruby_earth_explorer_cfi, "xv_stationvistime_compute", method_xv_stationvistime_compute, 8) ;

   Init_Ruby_Exception() ;

}

/* -------------------------------------------------------------------------- */

void Init_Ruby_Exception()
{
   rbException = rb_define_class_under(eocfi, "Error", rb_eStandardError) ;
   return ;
}

/* -------------------------------------------------------------------------- */
