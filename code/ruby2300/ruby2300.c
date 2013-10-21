/**
    
#########################################################################
#
# === Wrapper for Ruby to open2300 by Kenneth Lavrsen      
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#########################################################################

*/

#include <ruby.h>
#include <rw2300.h>

// Defining a space for information and references about the module to be stored internally

VALUE extruby2300          = Qnil ;
WEATHERSTATION ws2300      = Qnil ;

const char *wind_directions[]= {"N","NNE","NE","ENE","E","ESE","SE","SSE",
	                           "S","SSW","SW","WSW","W","WNW","NW","NNW"} ;
struct config_type config ;

VALUE wind_direction_degrees ;
VALUE wind_direction_pointing ;

int wind_index ;
double winddir[6];

/* Prototype for the initialization method - Ruby calls this, not you */

void Init_ruby2300() ;

/* Methods exposed to Ruby by the C extension */

VALUE method_open_weatherstation(VALUE self, VALUE config_file) ;
VALUE method_close_weatherstation(VALUE self) ;
VALUE method_temperature_outdoor(VALUE self) ;
VALUE method_temperature_indoor(VALUE self) ;
VALUE method_humidity_outdoor(VALUE self) ;
VALUE method_humidity_indoor(VALUE self) ;
VALUE method_rain_1h(VALUE self) ;
VALUE method_rain_24h(VALUE self) ;
VALUE method_rel_pressure(VALUE self) ;
VALUE method_abs_pressure(VALUE self) ;
VALUE method_dewpoint(VALUE self) ;
VALUE method_windchill(VALUE self) ;
VALUE method_wind_speed(VALUE self) ;
VALUE method_wind_all(VALUE self) ;
VALUE method_wind_pointing_degrees(VALUE self) ;
VALUE method_wind_direction(VALUE self) ;



// ----------------------------------------

void Init_ruby2300()
{
	extruby2300 = rb_define_module("Ruby2300") ;

	rb_define_method(extruby2300, "open_weatherstation", method_open_weatherstation, 1) ;	
   rb_define_method(extruby2300, "close_weatherstation", method_close_weatherstation, 0) ;
   rb_define_method(extruby2300, "temperature_outdoor", method_temperature_outdoor, 0) ;	
   rb_define_method(extruby2300, "temperature_indoor", method_temperature_indoor, 0) ;
   rb_define_method(extruby2300, "humidity_outdoor", method_humidity_outdoor, 0) ;
   rb_define_method(extruby2300, "humidity_indoor", method_humidity_indoor, 0) ;
   rb_define_method(extruby2300, "rain_1h", method_rain_1h, 0) ;
   rb_define_method(extruby2300, "rain_24h", method_rain_24h, 0) ;
   rb_define_method(extruby2300, "rel_pressure", method_rel_pressure, 0) ;
   rb_define_method(extruby2300, "abs_pressure", method_abs_pressure, 0) ;
   rb_define_method(extruby2300, "dewpoint", method_dewpoint, 0) ;
   rb_define_method(extruby2300, "windchill", method_windchill, 0) ;
   rb_define_method(extruby2300, "wind_speed", method_wind_speed, 0) ;
   rb_define_method(extruby2300, "wind_all", method_wind_all, 0) ;
   rb_define_method(extruby2300, "wind_pointing_degrees", method_wind_pointing_degrees, 0) ;
   rb_define_method(extruby2300, "wind_direction", method_wind_direction, 0) ;

   rb_define_variable("$wind_direction_degrees", &wind_direction_degrees) ;
   rb_define_variable("$wind_direction_pointing", &wind_direction_pointing) ;

}


VALUE method_open_weatherstation(VALUE self, VALUE config_file) 
{
   get_configuration(&config, StringValuePtr(config_file)) ;
   ws2300 = open_weatherstation(config.serial_device_name) ;
	return INT2NUM(ws2300) ;
}

VALUE method_close_weatherstation(VALUE self) 
{
   close_weatherstation(ws2300) ;
	int x = 0 ;
	return INT2NUM(x) ;
}

VALUE method_temperature_outdoor(VALUE self) 
{
	return rb_float_new(temperature_outdoor(ws2300, config.temperature_conv)) ;
}

VALUE method_temperature_indoor(VALUE self) 
{
	return rb_float_new(temperature_indoor(ws2300, config.temperature_conv)) ;
}

VALUE method_humidity_outdoor(VALUE self)
{
   return INT2NUM(humidity_outdoor(ws2300)) ;
}

VALUE method_humidity_indoor(VALUE self)
{
   return INT2NUM(humidity_indoor(ws2300)) ;
}


VALUE method_rain_24h(VALUE self) 
{
	return rb_float_new(rain_24h(ws2300, config.rain_conv_factor)) ;
}

VALUE method_rain_1h(VALUE self) 
{
	return rb_float_new(rain_1h(ws2300, config.rain_conv_factor)) ;
}

VALUE method_rel_pressure(VALUE self) 
{
	return rb_float_new(rel_pressure(ws2300, config.pressure_conv_factor)) ;
}

VALUE method_abs_pressure(VALUE self) 
{
	return rb_float_new(abs_pressure(ws2300, config.pressure_conv_factor)) ;
}

VALUE method_dewpoint(VALUE self) 
{
	return rb_float_new(dewpoint(ws2300, config.temperature_conv)) ;
}

VALUE method_windchill(VALUE self) 
{
	return rb_float_new(windchill(ws2300, config.temperature_conv)) ;
}

VALUE method_wind_speed(VALUE self) 
{
   double d = wind_current(ws2300, config.wind_speed_conv_factor, winddir) ;
   wind_direction_degrees = rb_float_new(winddir[0]) ;
	return rb_float_new(d) ;
}

VALUE method_wind_all(VALUE self) 
{
   double d = wind_all(ws2300, config.wind_speed_conv_factor, &wind_index, winddir) ;
   wind_direction_degrees = rb_float_new(winddir[0]) ;
   wind_direction_pointing = rb_str_new2(wind_directions[wind_index]) ;
	return rb_float_new(d) ;
}

VALUE method_wind_pointing_degrees(VALUE self) 
{
   double d = wind_all(ws2300, config.wind_speed_conv_factor, &wind_index, winddir) ;
   wind_direction_degrees = rb_float_new(winddir[0]) ;
   wind_direction_pointing = rb_str_new2(wind_directions[wind_index]) ;
	return rb_float_new(winddir[0]) ;
}

VALUE method_wind_direction(VALUE self) 
{
   double d = wind_all(ws2300, config.wind_speed_conv_factor, &wind_index, winddir) ;
   wind_direction_degrees = rb_float_new(winddir[0]) ;
   wind_direction_pointing = rb_str_new2(wind_directions[wind_index]) ;
	return rb_str_new2(wind_directions[wind_index]) ;
}


