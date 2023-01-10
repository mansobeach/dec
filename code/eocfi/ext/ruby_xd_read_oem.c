/**
    
#########################################################################
#
# === Wrapper for Ruby to EXPLORER DATA HANDLING CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
#
#
#########################################################################

*/


#include <ruby.h>

#include <explorer_data_handling.h>

static xd_oem_file oem_data ;
static xd_osv_list_read_configuration read_config ;
static int iDebug ;
extern VALUE rbException ;

VALUE method_xd_read_oem(
                                          VALUE self,
                                          VALUE file_name_,
                                          VALUE isDebugMode
                                          ) 
{
 
   iDebug = RTEST(isDebugMode) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ENTRY ruby_method_xd_read_oem\n") ;  
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

   char file_oem[XD_MAX_STR] ;
   strcpy(file_oem, StringValueCStr(file_name_)) ;
   
   if (iDebug == 1)
   {
      printf("DEBUG: ruby_method_xd_read_oem file_oem : %s\n", file_oem) ;
   }
   
   FILE *file;
   if ((file = fopen(file_oem, "r")))
   {
      if (iDebug == 1)
         printf("DEBUG: ruby_method_xd_read_oem file %s is available\n", file_oem) ;

      fclose(file) ;
   }
   else
   {
      if (iDebug == 1)
         printf("DEBUG: ruby_method_xd_read_oem file %s not found\n", file_oem) ;

      rb_raise(rbException, "ruby_method_xd_read_oem file %s not found", file_oem) ;
      
   }
   /* --------------------------------------------------- */


   /* --------------------------------------------------- */
   
   status = xd_read_oem(
                                       file_oem,
                                       &read_config, 
                                       &oem_data,
                                       ierr
                                       ) ;

   if (iDebug == 1)
   {
      printf("DEBUG: method_xd_read_oem xd_read_oem status: %ld ierr: %li\n", status, *ierr) ;  
   }

   if (status != XD_OK)
   {
      func_id = XD_READ_OEM_ID ;
      xo_get_msg(&func_id, ierr, &n, msg) ;
      xl_print_msg(&n, msg) ;
   }

   if (iDebug == 1)
   {
      printf("DEBUG: EXIT ruby_method_xd_read_oem\n") ;
   }

   return Data_Wrap_Struct(RBASIC (self)->klass, NULL, NULL, &oem_data) ;

}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_num_rec(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return LONG2NUM(p->num_rec) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_ccsds_oem_vers(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->ccsds_oem_vers) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_comment_header(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->comment_header) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_originator(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->originator) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_creation_date(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->creation_date) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_object_name(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->object_name) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_object_id(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->object_id) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_center_name(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->center_name) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_ref_frame(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->ref_frame) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_ref_frame_epoch(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->ref_frame_epoch) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_time_system(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->time_system) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_useable_start_time(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->useable_start_time) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_useable_stop_time(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->useable_stop_time) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_start_time(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->start_time) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_oem_metadata_stop_time(VALUE self) 
{
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return rb_str_new2(p->stop_time) ;
}

/* -------------------------------------------------------------------------- */

/*
VALUE method_xd_read_rec_oem_abs_orbit(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return LONG2NUM(p->osv_rec[idx].abs_orbit) ;
}
*/

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_rec_oem_utc_time(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return DBL2NUM(p->osv_rec[idx].utc_time) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_rec_oem_ref_frame(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return LONG2NUM(p->osv_rec[idx].ref_frame) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_rec_oem_time_ref_of(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return LONG2NUM(p->osv_rec[idx].time_ref_of) ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_rec_oem_pos(VALUE self, int idx_) 
{
   VALUE arrResult = rb_ary_new2(3) ;
   int idx = NUM2INT(idx_) ;
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   rb_ary_store(arrResult, 0, rb_float_new(p->osv_rec[idx].pos[0]) ) ;
   rb_ary_store(arrResult, 1, rb_float_new(p->osv_rec[idx].pos[1]) ) ;
   rb_ary_store(arrResult, 2, rb_float_new(p->osv_rec[idx].pos[2]) ) ;
   return arrResult ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_rec_oem_vel(VALUE self, int idx_) 
{
   VALUE arrResult = rb_ary_new2(3) ;
   int idx = NUM2INT(idx_) ;
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   rb_ary_store(arrResult, 0, rb_float_new(p->osv_rec[idx].vel[0]) ) ;
   rb_ary_store(arrResult, 1, rb_float_new(p->osv_rec[idx].vel[1]) ) ;
   rb_ary_store(arrResult, 2, rb_float_new(p->osv_rec[idx].vel[2]) ) ;
   return arrResult ;
}

/* -------------------------------------------------------------------------- */

VALUE method_xd_read_rec_oem_quality(VALUE self, int idx_) 
{
   int idx = NUM2INT(idx_) ;
   xd_oem_file* p ;
   Data_Get_Struct(self, xd_oem_file, p) ;
   return DBL2NUM(p->osv_rec[idx].quality) ;
}

/* -------------------------------------------------------------------------- */