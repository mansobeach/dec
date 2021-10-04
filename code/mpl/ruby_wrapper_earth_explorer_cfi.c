/**
    
#########################################################################
#
# === Wrapper for Ruby to EARTH EXPLORER CFI by DEIMOS Space S.L.U.      
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
#include <explorer_data_handling.h>
#include <explorer_file_handling.h>
#include <explorer_visibility.h>

/* Defining a space for information 
and references about the module to be stored internally */

static VALUE ruby_earth_explorer_cfi   = Qnil ;
static VALUE mpl                       = Qnil ;


/* Prototype for the initialization method - Ruby calls this, not you */

void Init_ruby_earth_explorer_cfi() ;

/* ========================================================= */
/*                                                           */
/* Methods exposed to Ruby by the C extension */
/*                                                           */

VALUE method_xo_check_library_version() ;
VALUE method_xo_time_to_orbit() ;
VALUE method_xo_position_on_orbit_to_time() ;
VALUE method_xd_read_station_id() ;
VALUE method_xd_read_station() ;
   VALUE method_xd_read_station_antenna() ;
   VALUE method_xd_read_station_purpose() ;
   VALUE method_xd_read_station_type() ;
   VALUE method_xd_read_station_station_alt() ;
   VALUE method_xd_read_station_station_lat() ;
   VALUE method_xd_read_station_station_long() ;
VALUE method_xv_stationvistime_compute() ;


/* ========================================================= */

/* -------------------------------------------------------------------------- */

void Init_ruby_earth_explorer_cfi()
{
	mpl                        = rb_define_module("MPL") ;
   ruby_earth_explorer_cfi    = rb_define_class_under(mpl, "Earth_Explorer_CFI", rb_cObject) ;

	rb_define_method(ruby_earth_explorer_cfi, "xo_check_library_version", method_xo_check_library_version, 1) ;
   rb_define_method(ruby_earth_explorer_cfi, "xo_time_to_orbit", method_xo_time_to_orbit, 3) ; 
   rb_define_method(ruby_earth_explorer_cfi, "xo_position_on_orbit_to_time", method_xo_position_on_orbit_to_time, 4) ;
   rb_define_method(ruby_earth_explorer_cfi, "xd_read_station_id", method_xd_read_station_id, 2) ;

   rb_define_method(ruby_earth_explorer_cfi, "xd_read_station", method_xd_read_station, 3) ;
   rb_define_method(ruby_earth_explorer_cfi, "antenna", method_xd_read_station_antenna, 0) ;
   rb_define_method(ruby_earth_explorer_cfi, "purpose", method_xd_read_station_purpose, 0) ;
   rb_define_method(ruby_earth_explorer_cfi, "type", method_xd_read_station_type, 0) ;
   rb_define_method(ruby_earth_explorer_cfi, "station_alt", method_xd_read_station_station_alt, 0) ;
   rb_define_method(ruby_earth_explorer_cfi, "station_lat", method_xd_read_station_station_lat, 0) ;
   rb_define_method(ruby_earth_explorer_cfi, "station_long", method_xd_read_station_station_long, 0) ;

   rb_define_method(ruby_earth_explorer_cfi, "xv_stationvistime_compute", method_xv_stationvistime_compute, 8) ;

}

/* -------------------------------------------------------------------------- */
