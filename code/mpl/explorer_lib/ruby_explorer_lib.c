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

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>

#include <explorer_lib.h>



/* Defining a space for information 
and references about the module to be stored internally */

static VALUE ruby_explorer_lib   = Qnil ;
static VALUE mpl                 = Qnil ;


/* Prototype for the initialization method - Ruby calls this, not you */

void Init_ruby_explorer_lib() ;

/* Methods exposed to Ruby by the C extension */

VALUE method_check_library_version() ;

/*
VALUE method_DateTime2OrbitAbsolute() ;
VALUE method_PositionInOrbit() ;
*/


/* -------------------------------------------------------------------------- */

void Init_ruby_explorer_lib()
{
	mpl                = rb_define_module("MPL") ;
   ruby_explorer_lib  = rb_define_class_under(mpl, "Explorer_Lib", rb_cObject) ;
	rb_define_method(ruby_explorer_lib, "check_library_version", method_check_library_version, 0) ;
   
   /*
   
   rb_define_method(ruby_explorer_orbit, "DateTime2OrbitAbsolute", method_DateTime2OrbitAbsolute, 2) ;

   rb_define_method(ruby_explorer_orbit, "PositionInOrbit", method_PositionInOrbit, 3) ;

*/

}

/* -------------------------------------------------------------------------- */

/*============================================================================*/
/*  EXPCFI check_library_version direct call          */
/*============================================================================*/


VALUE method_check_library_version() 
{
   printf("\n") ;
   printf("DEBUG: entry ruby_explorer_lib::method_check_library_version\n") ;  
   printf("\n") ;

   long lValue ;

   lValue = xl_check_library_version() ;
   
   printf("\n") ;
   printf("DEBUG: exit ruby_explorer_lib::method_check_library_version\n") ;  
   printf("\n") ;

   return LONG2NUM(lValue) ;
}


/* -------------------------------------------------------------------------- */



/*============================================================================*/
/*  MPL::PositionInOrbit 
      - full_path_OSF
      - Absolute_Orbit_Angle
      - ANX_Angle        */
/*============================================================================*/


/* -------------------------------------------------------------------------- */
