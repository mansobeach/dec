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

static xd_station_file station_data ;
static int iDebug ;

VALUE method_xd_read_station_file(
                                          VALUE self,
                                          VALUE strStationDB,
                                          VALUE isDebugMode
                                          ) 
{
 
   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_method_xd_read_station_file\n") ;  
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

   char station_file[XD_MAX_STR] ;
   strcpy (station_file, StringValueCStr(strStationDB)) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ruby_method_xd_read_station_file station_file: %s\n", station_file) ;  
   }
   
   /* --------------------------------------------------- */
   
   local_status = xd_read_station_file(
                                       station_file,
                                       &station_data, 
                                       xd_ierr
                                       ) ;

   func_id = XD_READ_STATION_FILE_ID ;

   if (local_status != XD_OK)
   {
      xd_get_msg(&func_id, xd_ierr, &n, msg) ;
      xd_print_msg(&n, msg) ;
   }
   else
   {
      if (iDebug == 1)
      {
         xd_get_msg(&func_id, xd_ierr, &n, msg) ;
         xd_print_msg(&n, msg) ;

         printf("xd_read_station_file OK") ;
         printf("\n") ;
         printf("station_data num records => %i \n", station_data.num_rec) ;

         for(n = 0 ; n < station_data.num_rec ;n++)
         {
            printf("station_data => %s \n", station_data.station_rec[n].station_id) ;
         }

      }
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT ruby_method_xd_read_station_file\n") ;
   }

   return Data_Wrap_Struct(RBASIC(self)->klass, NULL, NULL, &station_data) ;

}

/* -------------------------------------------------------------------------- */

/* Mapping of the struct xd_station_file */

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_file_num_rec(VALUE self) 
{
   xd_station_file* p ;
   Data_Get_Struct(self, xd_station_file, p) ;
   return INT2NUM(p->num_rec) ;
}

/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_station_file_xd_station_rec(VALUE self) 
{
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY method_xd_read_station_file_xd_station_rec\n") ;  
   }
   
   xd_station_file* p ;
   Data_Get_Struct(self, xd_station_file, p) ;
   printf("%i", p->num_rec) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: EXIT method_xd_read_station_file_xd_station_rec\n") ;  
   }
   return p->station_rec;

/*
   xd_station_file* p ;
   xd_station_rec* r ;
   Data_Get_Struct(self, xd_station_file, p) ;
   printf("%i", p->num_rec);
   printf("%s", station_data.station_rec[2].descriptor);
   printf("%s", station_data.station_rec->descriptor);
   printf("%s", p->station_rec->station_id);
   // return Data_Get_Struct(self, xd_station_file, p->station_rec) ;
   return TypedData_Wrap_Struct(self, station_data.station_rec, p); 
*/
}

/* -------------------------------------------------------------------------- */

