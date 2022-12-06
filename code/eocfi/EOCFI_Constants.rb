#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #EOCFI_Constants class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component (EOCFI)
### 
### Git: EOCFI_Constants,v $Id$ $Date$
###
### module EOCFI
###
#########################################################################

require 'rubygems'

module EOCFI
   
   # --------------------------------------------
   # XL_Time_model_enum
   XL_TIMEMOD_AUTO                           = -2
   XL_TIMEMOD_USER                           = -1
   XL_TIMEMOD_NONE                           = 0
   XL_TIMEMOD_IERS_B_PREDICTED               = 1
   XL_TIMEMOD_IERS_B_RESTITUTED              = 2
   XL_TIMEMOD_FOS_PREDICTED                  = 3
   XL_TIMEMOD_FOS_RESTITUTED                 = 4
   XL_TIMEMOD_DORIS_PRELIMINARY              = 5
   XL_TIMEMOD_DORIS_PRECISE                  = 6
   XL_TIMEMOD_DORIS_NAVIGATOR                = 7
   XL_TIMEMOD_OSF                            = 8
   XL_TIMEMOD_IERS_A_ONLY_PREDICTION         = 9
   XL_TIMEMOD_IERS_A_PREDICTION_AND_FORMULA  = 10
   XL_TIMEMOD_IERS_B_AND_A_ONLY_PREDICTION   = 11

   XL_Time_model_enum = {
      "XL_TIMEMOD_AUTO"                      => XL_TIMEMOD_AUTO,
      "XL_TIMEMOD_USER"                      => XL_TIMEMOD_USER,
      "XL_TIMEMOD_NONE"                      => XL_TIMEMOD_NONE,
      "XL_TIMEMOD_IERS_B_PREDICTED"          => XL_TIMEMOD_IERS_B_PREDICTED,
      "XL_TIMEMOD_IERS_B_RESTITUTED"         => XL_TIMEMOD_IERS_B_RESTITUTED,
      "XL_TIMEMOD_FOS_PREDICTED"             => XL_TIMEMOD_FOS_PREDICTED,
      "XL_TIMEMOD_FOS_RESTITUTED"            => XL_TIMEMOD_FOS_RESTITUTED,
      "XL_TIMEMOD_DORIS_PRELIMINARY"         => XL_TIMEMOD_DORIS_PRELIMINARY,
      "XL_TIMEMOD_DORIS_PRECISE"             => XL_TIMEMOD_DORIS_PRECISE,
      "XL_TIMEMOD_DORIS_NAVIGATOR"           => XL_TIMEMOD_DORIS_NAVIGATOR,
      "XL_TIMEMOD_OSF"                       => XL_TIMEMOD_OSF,
      "XL_TIMEMOD_IERS_A_ONLY_PREDICTION"    => XL_TIMEMOD_IERS_A_ONLY_PREDICTION,
      "XL_TIMEMOD_IERS_A_PREDICTION_AND_FORMULA"   => XL_TIMEMOD_IERS_A_PREDICTION_AND_FORMULA,
      "XL_TIMEMOD_IERS_B_AND_A_ONLY_PREDICTION"    => XL_TIMEMOD_IERS_B_AND_A_ONLY_PREDICTION
   }
   # --------------------------------------------
   
   # --------------------------------------------
   # XL_Time_init_mode_enum   
   XL_SEL_FILE    = 0
   XL_SEL_TIME    = 1
   XL_SEL_ORBIT   = 2
   XL_SEL_DEFAULT = 3

   XL_Time_init_mode_enum = {
      "XL_SEL_FILE"     => XL_SEL_FILE,
      "XL_SEL_TIME"     => XL_SEL_TIME,
      "XL_SEL_ORBIT"    => XL_SEL_ORBIT,
      "XL_SEL_DEFAULT"  => XL_SEL_DEFAULT
   }
   # --------------------------------------------

   # --------------------------------------------
   # XL_Time_ref_enum
   XL_TIME_UNDEF = -1
   XL_TIME_TAI   = 0
   XL_TIME_UTC   = 1
   XL_TIME_UT1   = 2
   XL_TIME_GPS   = 3

   XL_Time_ref_enum = {
      "XL_TIME_UNDEF"   => XL_TIME_UNDEF,
      "XL_TIME_TAI"     => XL_TIME_TAI,
      "XL_TIME_UTC"     => XL_TIME_UTC,
      "XL_TIME_UT1"     => XL_TIME_UT1,
      "XL_TIME_GPS"     => XL_TIME_GPS
   }

   # --------------------------------------------


end

## ==============================================================================
