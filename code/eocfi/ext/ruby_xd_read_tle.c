/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER DATA HANDLING CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
#
#
#########################################################################

https://celestrak.org/columns/v04n03/


AAAAAAAAAAAAAAAAAAAAAAAA
1 NNNNNU NNNNNAAA NNNNN.NNNNNNNN +.NNNNNNNN +NNNNN-N +NNNNN-N N NNNNN
2 NNNNN NNN.NNNN NNN.NNNN NNNNNNN NNN.NNNN NNN.NNNN NN.NNNNNNNNNNNNNN


Line 0 is a twenty-four character name (to be consistent with the name length in the NORAD SATCAT).

> [1.3] classification:
Field 1.3 indicates the security classification of the data—all publicly available data will have a 'U' in this field to indicate unclassified data
The column with a 'C' can only have a character representing the classification of the element set—normally either a 'U' for unclassified data or an 'S' for secret data (of course, only unclassified data are publicly available)

> [1.9] First Time Derivative of the Mean Motion
> [1.10] Second Time Derivative of Mean Motion (decimal point assumed)
First Time Derivative represents the first derivative of the mean motion divided by two, in units of revolutions per day2, 
and field 1.10 represents the second derivative of the mean motion divided by six, in units of revolutions per day3. 
Together, these two fields give a second-order picture of how the mean motion is changing with time. 
However, these two fields are not used by the SGP4/SDP4 orbital models (only by the simpler SGP model) and, therefore, serve no real purpose.

> [1.12] ephemeris type:
Field 1.12 represents the ephemeris type (i.e., orbital model) used to generate the data. 
Spacetrack Report Number 3 suggests the following assignments: 1=SGP, 2=SGP4, 3=SDP4, 4=SGP8, 5=SDP8. 
However, this value is used for internal analysis only—all distributed element sets have a value of zero and are generated using the SGP4/SDP4 orbital model (as appropriate).

> [1.13] element number:
Field 1.13 represents the element set number. 
Normally, this number is incremented each time a new element set is generated. 
In practice, however, this doesn't always happen. 
When operations switch between the primary and backup Space Control Centers, sometimes the element set numbers get out of sync, with some numbers being reused and others skipped. 
Unfortunately, this makes it difficult to tell if you have all the element sets for a particular object.

*/

#include <ruby.h>

#include <explorer_data_handling.h>

static xd_tle_file tle_data ;
static int iDebug ;
extern VALUE rbException ;

VALUE method_xd_read_tle(
                                          VALUE self,
                                          VALUE file_name_,
                                          VALUE satellite_name_,
                                          VALUE isDebugMode
                                          ) 
{
 
   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_method_xd_read_tle\n") ;  
   }
   
   /* --------------------------------------------------- */
   /* error handling */
   long n,
   func_id ; /* Error codes vector */
   /* --------------------------------------------------- */
   char msg[XD_MAX_COD][XD_MAX_STR] ; /* Error messages vector */
   /* --------------------------------------------------- */
   long ierr[XD_ERR_VECTOR_MAX_LENGTH] ;
   long status ;
   /* --------------------------------------------------- */

   char file_tle[XD_MAX_STR] ;
   char satellite_name[XD_MAX_STR] ;
   strcpy(file_tle, StringValueCStr(file_name_)) ;
   strcpy(satellite_name, StringValueCStr(satellite_name_)) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ruby_method_xd_read_tle file_tle: %s\n", file_tle) ;  
   }
   
   FILE *file;
   if ((file = fopen(file_tle, "r")))
   {
      if (iDebug == 1)
         printf("DEBUG: ruby_method_xd_read_tle file %s is available\n", file_tle) ;

      fclose(file) ;
   }
   else
   {
      if (iDebug == 1)
         printf("DEBUG: ruby_method_xd_read_tle file %s not found\n", file_tle) ;

      rb_raise(rbException, "ruby_method_xd_read_tle file %s not found", file_tle) ;
      
   }
   /* --------------------------------------------------- */


   /* --------------------------------------------------- */
   
   status = xd_read_tle(
                                       file_tle,
                                       satellite_name,
                                       &tle_data, 
                                       ierr
                                       ) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xd_read_tle xd_read_tle status: %ld ierr: %li\n", status, *ierr) ;  
   }

   if (status != XD_OK)
   {
      func_id = XD_READ_TLE_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }

   if (iDebug == 1 && status == XD_OK)
   {
    
      printf("xd_read_tle OK \n") ;
      printf("tle_data num records => %li \n ", tle_data.num_rec) ;

      for(n = 0 ; n < tle_data.num_rec ;n++)
      {
         printf("tle_rec[%li] 0 NORAD SATCAT                   => %s \n", n, tle_data.tle_rec[n].norad_satcat) ;
         printf("tle_rec[%li] 1.2  satellite number            => %ld \n", n, tle_data.tle_rec[n].sat_number) ;
         printf("tle_rec[%li] 1.3  classification              => %c \n", n, tle_data.tle_rec[n].classification) ;
         printf("tle_rec[%li] 1.[4,5,6] int. designator        => %s \n", n, tle_data.tle_rec[n].int_des) ;
         printf("tle_rec[%li] 1.[7,8] Epoch MJD2000            => %lf \n", n, tle_data.tle_rec[n].time) ;
         printf("tle_rec[%li] 1.9  First Time Derivative of Mean Motion    => %lf \n", n, tle_data.tle_rec[n].n_1st) ;
         printf("tle_rec[%li] 1.10 Second Time Derivative of Mean Motion   => %lf \n", n, tle_data.tle_rec[n].n_2nd) ;
         printf("tle_rec[%li] 1.11 BSTAR drag term             => %lf \n", n, tle_data.tle_rec[n].bstar) ;
         printf("tle_rec[%ld] 1.12 Ephemeris type              => %d \n", n, tle_data.tle_rec[n].ephemeris_type) ;
         printf("tle_rec[%li] 1.13 Element number              => %d \n", n, tle_data.tle_rec[n].index) ;
         printf("tle_rec[%li] 1.14 checksum1                   => %d \n", n, tle_data.tle_rec[n].checksum1) ;
         printf("tle_rec[%li] 2.2  satellite number            => %ld \n", n, tle_data.tle_rec[n].sat_number) ;
         printf("tle_rec[%li] 2.3  Inclination                 => %lf degrees\n", n, tle_data.tle_rec[n].i) ;
         printf("tle_rec[%li] 2.4  Right Ascension of the Ascending Node => %lf degrees\n", n, tle_data.tle_rec[n].ra) ;
         printf("tle_rec[%li] 2.5  Eccentricity                => %lf \n", n, tle_data.tle_rec[n].e) ;
         printf("tle_rec[%li] 2.6  Argument of Perigee         => %lf degrees\n", n, tle_data.tle_rec[n].w) ;
         printf("tle_rec[%li] 2.7  Mean Anomaly                => %lf degrees\n", n, tle_data.tle_rec[n].m) ;
         printf("tle_rec[%li] 2.8  Mean Motion                 => %lf rev/day\n", n, tle_data.tle_rec[n].n) ;
         printf("tle_rec[%li] 2.9  Revolution number  @ epoch  => %ld \n", n, tle_data.tle_rec[n].abs_orbit) ;
         printf("tle_rec[%li] 2.10 checksum2                   => %d \n", n, tle_data.tle_rec[n].checksum2) ;
         /* printf("tle_rec[%li] Rev. number @epoch   => %ld \n", n, tle_data.tle_rec[n].abs_orbit) ; */
      }

   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT ruby_method_xd_read_tle\n") ;
   }

   return Data_Wrap_Struct(RBASIC(self)->klass, NULL, NULL, &tle_data) ;

}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_file_num_rec(VALUE self) 
{
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return LONG2NUM(p->num_rec) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_norad_satcat(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return rb_str_new2(p->tle_rec[idx].norad_satcat) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_sat_number(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return LONG2NUM(p->tle_rec[idx].sat_number) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_classification(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return rb_sprintf("%c", p->tle_rec[idx].classification) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_int_des(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return rb_str_new2(p->tle_rec[idx].int_des) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_inclination(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].i) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_eccentricity(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].e) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_time(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].time) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_mean_anomaly(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].m) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_mean_motion(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].n) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_1st_mean_motion(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].n_1st) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_2nd_mean_motion(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].n_2nd) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_bstar(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].bstar) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_RAAN(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].ra) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_w(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return DBL2NUM(p->tle_rec[idx].w) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_ephemeris_type(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return LONG2NUM(p->tle_rec[idx].ephemeris_type) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_checksum1(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return LONG2NUM(p->tle_rec[idx].checksum1) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_checksum2(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return LONG2NUM(p->tle_rec[idx].checksum2) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_element_number(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return INT2NUM(p->tle_rec[idx].index) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_tle_rec_abs_orbit(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_tle_file* p ;
   Data_Get_Struct(self, xd_tle_file, p) ;
   return LONG2NUM(p->tle_rec[idx].abs_orbit) ;
}

/* -------------------------------------------------------------------------- */