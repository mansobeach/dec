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

extern VALUE rbException ;

VALUE method_xd_read_station_id(
                                          VALUE self,
                                          VALUE strStationDB,
                                          VALUE isDebugMode
                                          ) 
{
 
   int iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_method_xd_read_station_id::method_xd_read_station_id\n") ;  
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

   FILE *file;
   if ((file = fopen(stat_file, "r")))
   {
      if (iDebug == 1)
         printf("DEBUG: ruby_method_xd_read_station_id file %s is available\n", stat_file) ;

      fclose(file) ;
   }
   else
   {
      if (iDebug == 1)
         printf("DEBUG: ruby_method_xd_read_station_id file %s not found\n", stat_file) ;

      rb_raise(rbException, "ruby_method_xd_read_station_id file %s not found", stat_file) ;
      
   }
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
      printf("DEBUG: ENTRY ruby_method_xd_read_station_id::method_xd_read_station_id\n") ;  
   }
   
   return r_array_station_id ;
      
}

/* -------------------------------------------------------------------------- */


/* -------------------------------------------------------------------------- */
