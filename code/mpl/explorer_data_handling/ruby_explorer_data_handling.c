/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER_DATA_HANDLING CFI by DEIMOS Space S.L.U.      
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

#include <explorer_data_handling.h>

/* Defining a space for information 
and references about the module to be stored internally */

static VALUE ruby_explorer_data_handling     = Qnil ;
static VALUE mpl                             = Qnil ;

/* Prototype for the initialization method - Ruby calls this, not you */

void Init_ruby_explorer_data_handling() ;

/* Methods exposed to Ruby by the C extension */

VALUE method_xd_read_station_id() ;

/* -------------------------------------------------------------------------- */

void Init_ruby_explorer_data_handling()
{
	mpl                            = rb_define_module("MPL") ;
   
   ruby_explorer_data_handling    = rb_define_class_under(mpl, "Explorer_Data_Handling", rb_cObject) ;

	rb_define_method(ruby_explorer_data_handling, "ReadStationID", method_xd_read_station_id, 2) ;

}


/* -------------------------------------------------------------------------- */

/*============================================================================*/
/*  EXPCFI xv_station_vis_time direct call          */
/*============================================================================*/


VALUE method_xd_read_station_id(
                                          VALUE self,
                                          VALUE strStationDB,
                                          VALUE isDebugMode
                                          ) 
{
 
   int iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("\n") ;
      printf("DEBUG: entry ruby_explorer_data_handling::method_xd_read_station_id\n") ;  
      printf("\n") ;
   }
   
   /* --------------------------------------------------- */
   /* error handling */
   
   long n,
       func_id ; /* Error codes vector */
   
   /* --------------------------------------------------- */
   char msg[XD_MAX_COD][XD_MAX_STR] ; /* Error messages vector */
   /* --------------------------------------------------- */

   long xd_ierr[XD_ERR_VECTOR_MAX_LENGTH] ;
   long local_status ;

   /* --------------------------------------------------- */

   char stat_file[XD_MAX_STR] ;
   strcpy (stat_file, StringValueCStr(strStationDB)) ;

   /* --------------------------------------------------- */

   long num_stations ;
   char ** station_list_id ;

   local_status = xd_read_station_id(
                                       stat_file,
                                       &num_stations, 
                                       &station_list_id, 
                                       xd_ierr
                                       ) ;
   if (local_status != XD_OK)
   {
      func_id = XD_READ_STATION_ID ;
      xd_get_msg(&func_id, xd_ierr, &n, msg) ;
      xd_print_msg(&n, msg) ;
   }
   else
   {
      if (iDebug == 1)
      {
         printf("xd_read_station_id OK") ;
         printf("\n") ;
      }
   }

   /* --------------------------------------------------- */

   VALUE r_array_station_id = rb_ary_new2(num_stations) ;

   /* --------------------------------------------------- */

   for(n=0;n<num_stations;n++)
   {
      /* printf("\n%s\n",station_list_id[n]) ;  */
      rb_ary_push(r_array_station_id, rb_str_new2(station_list_id[n]) ) ;
   }

   /* --------------------------------------------------- */

   xd_free_station_id (&station_list_id) ;

   if (iDebug == 1)
   {
      printf("\n") ;
      printf("DEBUG: exit ruby_explorer_data_handling::method_xd_read_station_id\n") ;  
      printf("\n") ;
	}
   
   return r_array_station_id ;
      
}

/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
