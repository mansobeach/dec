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
   # XD_File_types
   
   XD_UNKNOWN_TYPE         = -1,
   XD_AUTO                 = 0
   XD_ORBIT_CHANGE         = 1
   XD_STATE_VECTOR         = 2
   XD_OSF_TYPE             = 3
   XD_POF_TYPE             = 4
   XD_ROF_TYPE             = 5
   XD_DORIS_TYPE           = 6
   XD_POF_N_DORIS_TYPE     = 7
   XD_OEF_OSF_TYPE         = 8
   XD_OEF_POF_TYPE         = 9
   XD_IERS_B_TYPE          = 10
   XD_TLE_TYPE             = 11
   XD_STF_TYPE             = 12
   XD_DORISPREC_TYPE       = 13
   XD_DORISPREM_TYPE       = 14
   XD_ATT_TYPE             = 15
   XD_SCF_TYPE             = 16
   XD_PRECISE_PROPAG_TYPE  = 17
   XD_DEMCFG_TYPE          = 18
   XD_SATCFG_TYPE          = 19
   XD_GND_DB_TYPE          = 20
   XD_SW_DEF_TYPE          = 21
   XD_ZON_DB_TYPE          = 22
   XD_STR1ATT_TYPE         = 23
   XD_IERS_A_TYPE          = 24
   XD_IERS_B_AND_A_TYPE    = 25
   XD_ATT_DEF_TYPE         = 26
   XD_USER_OSV_LIST_TYPE   = 27
   XD_SP3_TYPE             = 28
   XD_OSF_POF_MODE         = 29
   XD_OSF_ROF_MODE         = 30
   XD_OSF_DORIS_MODE       = 31
   XD_OEM_TYPE             = 32
   XD_OSF_OEM_MODE         = 33
   XD_FOV_TYPE             = 34
   XD_AEM_TYPE             = 35
   XD_FILE_TYPE_MAX_VALUE  = 36
  
   # --------------------------------------------

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

   # --------------------------------------------
   # XL_Ascii_enum;
   
   XL_ASCII_UNDEF                   = -1
   XL_ASCII_STD                     = 11
   XL_ASCII_STD_REF                 = 12
   XL_ASCII_STD_MICROSEC            = 13
   XL_ASCII_STD_REF_MICROSEC        = 14
   XL_ASCII_COMPACT                 = 21
   XL_ASCII_COMPACT_REF             = 22
   XL_ASCII_COMPACT_MICROSEC        = 23
   XL_ASCII_COMPACT_REF_MICROSEC    = 24
   XL_ASCII_ENVI                    = 31
   XL_ASCII_ENVI_REF                = 32
   XL_ASCII_ENVI_MICROSEC           = 33
   XL_ASCII_ENVI_REF_MICROSEC       = 34
   XL_ASCII_CCSDSA                  = 41
   XL_ASCII_CCSDSA_REF              = 42
   XL_ASCII_CCSDSA_MICROSEC         = 43
   XL_ASCII_CCSDSA_REF_MICROSEC     = 44
   XL_ASCII_CCSDSA_COMPACT          = 51
   XL_ASCII_CCSDSA_COMPACT_REF      = 52
   XL_ASCII_CCSDSA_COMPACT_MICROSEC = 53
   XL_ASCII_CCSDSA_COMPACT_REF_MICROSEC = 54
  
   XL_Ascii_enum = {
      "XL_ASCII_UNDEF"                       => XL_ASCII_UNDEF,
      "XL_ASCII_STD"                         => XL_ASCII_STD,
      "XL_ASCII_STD_REF"                     => XL_ASCII_STD_REF,
      "XL_ASCII_STD_MICROSEC"                => XL_ASCII_STD_MICROSEC,
      "XL_ASCII_STD_REF_MICROSEC"            => XL_ASCII_STD_REF_MICROSEC,
      "XL_ASCII_COMPACT"                     => XL_ASCII_COMPACT,
      "XL_ASCII_COMPACT_REF"                 => XL_ASCII_COMPACT_REF,
      "XL_ASCII_COMPACT_MICROSEC"            => XL_ASCII_COMPACT_MICROSEC,
      "XL_ASCII_COMPACT_REF_MICROSEC"        => XL_ASCII_COMPACT_REF_MICROSEC,
      "XL_ASCII_ENVI"                        => XL_ASCII_ENVI,
      "XL_ASCII_ENVI_REF"                    => XL_ASCII_ENVI_REF,
      "XL_ASCII_ENVI_MICROSEC"               => XL_ASCII_ENVI_MICROSEC,
      "XL_ASCII_CCSDSA_REF_MICROSEC"         => XL_ASCII_CCSDSA_REF_MICROSEC,
      "XL_ASCII_CCSDSA_COMPACT"              => XL_ASCII_CCSDSA_COMPACT,
      "XL_ASCII_CCSDSA_COMPACT_REF"          => XL_ASCII_CCSDSA_COMPACT_REF,
      "XL_ASCII_CCSDSA_COMPACT_MICROSEC"     => XL_ASCII_CCSDSA_COMPACT_MICROSEC,
      "XL_ASCII_CCSDSA_COMPACT_REF_MICROSEC" => XL_ASCII_CCSDSA_COMPACT_REF_MICROSEC
   }
   # --------------------------------------------

   # --------------------------------------------
   # Processing time format ID */
   
   XL_PROC = 0

   XL_Proc_enum = {
      "XL_PROC" => XL_PROC
   }
   # --------------------------------------------

   # --------------------------------------------
   # XO_Sat_id_enum
   XL_SAT_DEFAULT       = 0
   XO_SAT_DEFAULT       = 0
   
   XL_SAT_SENTINEL_2A   = 126
   XO_SAT_SENTINEL_2A   = 126
   XL_SAT_SENTINEL_2B   = 127
   XO_SAT_SENTINEL_2B   = 127
   XL_SAT_SENTINEL_2C   = 128
   XO_SAT_SENTINEL_2C   = 128
   
   XL_SAT_GENERIC       = 200
   XO_SAT_GENERIC       = 200
   
   XL_SAT_GENERIC_GEO   = 300
   XO_SAT_GENERIC_GEO   = 300
   
   XL_SAT_GENERIC_MEO   = 400
   XO_SAT_GENERIC_MEO   = 400
   
   XO_Sat_id_enum = {
      "XL_SAT_DEFAULT"        => XL_SAT_DEFAULT,
      "XO_SAT_DEFAULT"        => XO_SAT_DEFAULT,
      "XL_SAT_SENTINEL_2A"    => XL_SAT_SENTINEL_2A,
      "XO_SAT_SENTINEL_2A"    => XO_SAT_SENTINEL_2A,
      "XL_SAT_SENTINEL_2B"    => XL_SAT_SENTINEL_2B,
      "XO_SAT_SENTINEL_2B"    => XO_SAT_SENTINEL_2B,
      "XL_SAT_SENTINEL_2C"    => XL_SAT_SENTINEL_2C,
      "XL_SAT_GENERIC"        => XL_SAT_GENERIC,
      "XO_SAT_GENERIC"        => XO_SAT_GENERIC,
      "XL_SAT_GENERIC_GEO"    => XL_SAT_GENERIC_GEO,
      "XO_SAT_GENERIC_GEO"    => XO_SAT_GENERIC_GEO,
      "XL_SAT_GENERIC_MEO"    => XL_SAT_GENERIC_MEO,
      "XO_SAT_GENERIC_MEO"    => XO_SAT_GENERIC_MEO
   }
   # --------------------------------------------

   # --------------------------------------------
   # XO_Time_init_mode
  
   XO_SEL_FILE       = XL_SEL_FILE
   XO_SEL_TIME       = XL_SEL_TIME
   XO_SEL_ORBIT      = XL_SEL_ORBIT
   XO_SEL_DEFAULT    = XL_SEL_DEFAULT
 
   XO_Time_init_mode = {
      "XO_SEL_FILE"        => XO_SEL_FILE,
      "XO_SEL_TIME"        => XO_SEL_TIME,
      "XO_SEL_ORBIT"       => XO_SEL_ORBIT,
      "XO_SEL_DEFAULT"     => XO_SEL_DEFAULT
   }
   # --------------------------------------------

   # XO_Orbit_init_mode
   
   XO_ORBIT_INIT_UNKNOWN_MODE                = -1
   XO_ORBIT_INIT_AUTO                        = XD_AUTO
   XO_ORBIT_INIT_ORBIT_CHANGE_MODE           = XD_ORBIT_CHANGE
   XO_ORBIT_INIT_STATE_VECTOR_MODE           = XD_STATE_VECTOR
   XO_ORBIT_INIT_OSF_MODE                    = XD_OSF_TYPE
   XO_ORBIT_INIT_POF_MODE                    = XD_POF_TYPE
   XO_ORBIT_INIT_ROF_MODE                    = XD_ROF_TYPE
   XO_ORBIT_INIT_DORIS_MODE                  = XD_DORIS_TYPE
   XO_ORBIT_INIT_POF_N_DORIS_MODE            = XD_POF_N_DORIS_TYPE
   XO_ORBIT_INIT_OEF_OSF_MODE                = XD_OEF_OSF_TYPE
   XO_ORBIT_INIT_OEF_POF_MODE                = XD_OEF_POF_TYPE
   XO_ORBIT_INIT_TLE_MODE                    = XD_TLE_TYPE
   XO_ORBIT_INIT_SP3_MODE                    = XD_SP3_TYPE
   XO_ORBIT_INIT_OEM_MODE                    = XD_OEM_TYPE
   XO_ORBIT_INIT_STATE_VECTOR_PRECISE_MODE   = 33
   XO_ORBIT_INIT_POF_PRECISE_MODE            = 34
   XO_ORBIT_INIT_ROF_PRECISE_MODE            = 35
   XO_ORBIT_INIT_DORIS_PRECISE_MODE          = 36
   XO_ORBIT_INIT_OEF_POF_PRECISE_MODE        = 37
   XO_ORBIT_INIT_POF_N_DORIS_PRECISE_MODE    = 38
   XO_ORBIT_INIT_GEO_LON_MODE                = 39
   XO_ORBIT_INIT_TLE_SGP4_MODE               = 40
   XO_ORBIT_INIT_TLE_SDP4_MODE               = 41
   XO_ORBIT_INIT_USER_OSV_LIST_MODE          = 42
   XO_ORBIT_INIT_POF_ORBNUM_ADJ_MODE         = 43
   XO_ORBIT_INIT_ROF_ORBNUM_ADJ_MODE         = 44
   XO_ORBIT_INIT_DORIS_ORBNUM_ADJ_MODE       = 45
   XO_ORBIT_INIT_OEM_ORBNUM_ADJ_MODE         = 46
   XO_ORBIT_INIT_MAX_VALUE                   = 47
 
   XO_Orbit_init_mode = {
      "XO_ORBIT_INIT_UNKNOWN_MODE"              => XO_ORBIT_INIT_UNKNOWN_MODE,
      "XO_ORBIT_INIT_AUTO"                      => XO_ORBIT_INIT_AUTO,
      "XO_ORBIT_INIT_ORBIT_CHANGE_MODE"         => XO_ORBIT_INIT_ORBIT_CHANGE_MODE,
      "XO_ORBIT_INIT_STATE_VECTOR_MODE"         => XO_ORBIT_INIT_STATE_VECTOR_MODE,
      "XO_ORBIT_INIT_OSF_MODE"                  => XO_ORBIT_INIT_OSF_MODE,
      "XO_ORBIT_INIT_POF_MODE"                  => XO_ORBIT_INIT_POF_MODE,
      "XO_ORBIT_INIT_ROF_MODE"                  => XO_ORBIT_INIT_ROF_MODE,
      "XO_ORBIT_INIT_DORIS_MODE"                => XO_ORBIT_INIT_DORIS_MODE,
      "XO_ORBIT_INIT_POF_N_DORIS_MODE"          => XO_ORBIT_INIT_POF_N_DORIS_MODE,
      "XO_ORBIT_INIT_OEF_OSF_MODE"              => XO_ORBIT_INIT_OEF_OSF_MODE,
      "XO_ORBIT_INIT_OEF_POF_MODE"              => XO_ORBIT_INIT_OEF_POF_MODE,
      "XO_ORBIT_INIT_TLE_MODE"                  => XO_ORBIT_INIT_TLE_MODE,
      "XO_ORBIT_INIT_SP3_MODE"                  => XO_ORBIT_INIT_SP3_MODE,
      "XO_ORBIT_INIT_OEM_MODE"                  => XO_ORBIT_INIT_OEM_MODE,
      "XO_ORBIT_INIT_STATE_VECTOR_PRECISE_MODE" => XO_ORBIT_INIT_STATE_VECTOR_PRECISE_MODE,
      "XO_ORBIT_INIT_POF_PRECISE_MODE"          => XO_ORBIT_INIT_POF_PRECISE_MODE,
      "XO_ORBIT_INIT_ROF_PRECISE_MODE"          => XO_ORBIT_INIT_ROF_PRECISE_MODE,
      "XO_ORBIT_INIT_DORIS_PRECISE_MODE"        => XO_ORBIT_INIT_DORIS_PRECISE_MODE,
      "XO_ORBIT_INIT_OEF_POF_PRECISE_MODE"      => XO_ORBIT_INIT_OEF_POF_PRECISE_MODE,
      "XO_ORBIT_INIT_POF_N_DORIS_PRECISE_MODE"  => XO_ORBIT_INIT_POF_N_DORIS_PRECISE_MODE,
      "XO_ORBIT_INIT_GEO_LON_MODE"              => XO_ORBIT_INIT_GEO_LON_MODE,
      "XO_ORBIT_INIT_TLE_SGP4_MODE"             => XO_ORBIT_INIT_TLE_SGP4_MODE,
      "XO_ORBIT_INIT_TLE_SDP4_MODE"             => XO_ORBIT_INIT_TLE_SDP4_MODE,
      "XO_ORBIT_INIT_USER_OSV_LIST_MODE"        => XO_ORBIT_INIT_USER_OSV_LIST_MODE,
      "XO_ORBIT_INIT_POF_ORBNUM_ADJ_MODE"       => XO_ORBIT_INIT_POF_ORBNUM_ADJ_MODE,
      "XO_ORBIT_INIT_ROF_ORBNUM_ADJ_MODE"       => XO_ORBIT_INIT_ROF_ORBNUM_ADJ_MODE,
      "XO_ORBIT_INIT_DORIS_ORBNUM_ADJ_MODE"     => XO_ORBIT_INIT_DORIS_ORBNUM_ADJ_MODE,
      "XO_ORBIT_INIT_OEM_ORBNUM_ADJ_MODE"       => XO_ORBIT_INIT_OEM_ORBNUM_ADJ_MODE,
      "XO_ORBIT_INIT_MAX_VALUE"                 => XO_ORBIT_INIT_MAX_VALUE
   }
   # --------------------------------------------

   # --------------------------------------------
   # XO_ORBIT_INFO_EXTRA_enum
   
   XO_ORBIT_INFO_EXTRA_REPEAT_CYCLE    = 0
   XO_ORBIT_INFO_EXTRA_CYCLE_LENGTH    = 1
   XO_ORBIT_INFO_EXTRA_MLST_DRIFT      = 2
   XO_ORBIT_INFO_EXTRA_MLST            = 3
   XO_ORBIT_INFO_EXTRA_ANX_LONG        = 4
   XO_ORBIT_INFO_EXTRA_UTC_ANX         = 5
   XO_ORBIT_INFO_EXTRA_POS_X           = 6
   XO_ORBIT_INFO_EXTRA_POS_Y           = 7
   XO_ORBIT_INFO_EXTRA_POS_Z           = 8
   XO_ORBIT_INFO_EXTRA_VEL_X           = 9
   XO_ORBIT_INFO_EXTRA_VEL_Y           = 10
   XO_ORBIT_INFO_EXTRA_VEL_Z           = 11
   XO_ORBIT_INFO_EXTRA_MEAN_KEPL_A     = 12
   XO_ORBIT_INFO_EXTRA_MEAN_KEPL_E     = 13
   XO_ORBIT_INFO_EXTRA_MEAN_KEPL_I     = 14
   XO_ORBIT_INFO_EXTRA_MEAN_KEPL_RA    = 15
   XO_ORBIT_INFO_EXTRA_MEAN_KEPL_W     = 16
   XO_ORBIT_INFO_EXTRA_MEAN_KEPL_M     = 17
   XO_ORBIT_INFO_EXTRA_OSC_KEPL_A      = 18
   XO_ORBIT_INFO_EXTRA_OSC_KEPL_E      = 19
   XO_ORBIT_INFO_EXTRA_OSC_KEPL_I      = 20
   XO_ORBIT_INFO_EXTRA_OSC_KEPL_RA     = 21
   XO_ORBIT_INFO_EXTRA_OSC_KEPL_W      = 22
   XO_ORBIT_INFO_EXTRA_OSC_KEPL_M      = 23
   XO_ORBIT_INFO_EXTRA_NODAL_PERIOD    = 24
   XO_ORBIT_INFO_EXTRA_UTC_SMX         = 25
   XO_ORBIT_INFO_EXTRA_NUM_ELEMENTS    = 26
 
   XO_ORBIT_INFO_EXTRA_enum = {
      "XO_ORBIT_INFO_EXTRA_REPEAT_CYCLE"     => XO_ORBIT_INFO_EXTRA_REPEAT_CYCLE,
      "XO_ORBIT_INFO_EXTRA_CYCLE_LENGTH"     => XO_ORBIT_INFO_EXTRA_CYCLE_LENGTH,
      "XO_ORBIT_INFO_EXTRA_MLST_DRIFT"       => XO_ORBIT_INFO_EXTRA_MLST_DRIFT,
      "XO_ORBIT_INFO_EXTRA_MLST"             => XO_ORBIT_INFO_EXTRA_MLST,
      "XO_ORBIT_INFO_EXTRA_ANX_LONG"         => XO_ORBIT_INFO_EXTRA_ANX_LONG,
      "XO_ORBIT_INFO_EXTRA_UTC_ANX"          => XO_ORBIT_INFO_EXTRA_UTC_ANX,
      "XO_ORBIT_INFO_EXTRA_POS_X"            => XO_ORBIT_INFO_EXTRA_POS_X,
      "XO_ORBIT_INFO_EXTRA_POS_Y"            => XO_ORBIT_INFO_EXTRA_POS_Y,
      "XO_ORBIT_INFO_EXTRA_POS_Z"            => XO_ORBIT_INFO_EXTRA_POS_Z,
      "XO_ORBIT_INFO_EXTRA_VEL_X"            => XO_ORBIT_INFO_EXTRA_VEL_X,
      "XO_ORBIT_INFO_EXTRA_VEL_Y"            => XO_ORBIT_INFO_EXTRA_VEL_Y,
      "XO_ORBIT_INFO_EXTRA_VEL_Z"            => XO_ORBIT_INFO_EXTRA_VEL_Z,
      "XO_ORBIT_INFO_EXTRA_MEAN_KEPL_A"      => XO_ORBIT_INFO_EXTRA_MEAN_KEPL_A,
      "XO_ORBIT_INFO_EXTRA_MEAN_KEPL_E"      => XO_ORBIT_INFO_EXTRA_MEAN_KEPL_E,
      "XO_ORBIT_INFO_EXTRA_MEAN_KEPL_I"      => XO_ORBIT_INFO_EXTRA_MEAN_KEPL_I,
      "XO_ORBIT_INFO_EXTRA_MEAN_KEPL_RA"     => XO_ORBIT_INFO_EXTRA_MEAN_KEPL_RA,
      "XO_ORBIT_INFO_EXTRA_MEAN_KEPL_W"      => XO_ORBIT_INFO_EXTRA_MEAN_KEPL_W,
      "XO_ORBIT_INFO_EXTRA_MEAN_KEPL_M"      => XO_ORBIT_INFO_EXTRA_MEAN_KEPL_M,
      "XO_ORBIT_INFO_EXTRA_OSC_KEPL_A"       => XO_ORBIT_INFO_EXTRA_OSC_KEPL_A,
      "XO_ORBIT_INFO_EXTRA_OSC_KEPL_E"       => XO_ORBIT_INFO_EXTRA_OSC_KEPL_E,
      "XO_ORBIT_INFO_EXTRA_OSC_KEPL_I"       => XO_ORBIT_INFO_EXTRA_OSC_KEPL_I,
      "XO_ORBIT_INFO_EXTRA_OSC_KEPL_RA"      => XO_ORBIT_INFO_EXTRA_OSC_KEPL_RA,
      "XO_ORBIT_INFO_EXTRA_OSC_KEPL_W"       => XO_ORBIT_INFO_EXTRA_OSC_KEPL_W,
      "XO_ORBIT_INFO_EXTRA_OSC_KEPL_M"       => XO_ORBIT_INFO_EXTRA_OSC_KEPL_M,
      "XO_ORBIT_INFO_EXTRA_NODAL_PERIOD"     => XO_ORBIT_INFO_EXTRA_NODAL_PERIOD,
      "XO_ORBIT_INFO_EXTRA_UTC_SMX"          => XO_ORBIT_INFO_EXTRA_UTC_SMX,
      "XO_ORBIT_INFO_EXTRA_NUM_ELEMENTS"     => XO_ORBIT_INFO_EXTRA_NUM_ELEMENTS
   }

   UNIT_XO_ORBIT_INFO_EXTRA_REPEAT_CYCLE     = "days"
   UNIT_XO_ORBIT_INFO_EXTRA_CYCLE_LENGTH     = "orbits"
   UNIT_XO_ORBIT_INFO_EXTRA_MLST_DRIFT       = "seconds/day"
   UNIT_XO_ORBIT_INFO_EXTRA_MLST             = "hours"
   UNIT_XO_ORBIT_INFO_EXTRA_ANX_LONG         = "degrees"
   UNIT_XO_ORBIT_INFO_EXTRA_UTC_ANX          = "days (MJD2000)"
   UNIT_XO_ORBIT_INFO_EXTRA_POS_X            = "m"
   UNIT_XO_ORBIT_INFO_EXTRA_POS_Y            = "m"
   UNIT_XO_ORBIT_INFO_EXTRA_POS_Z            = "m"
   UNIT_XO_ORBIT_INFO_EXTRA_VEL_X            = "m/s"
   UNIT_XO_ORBIT_INFO_EXTRA_VEL_Y            = "m/s"
   UNIT_XO_ORBIT_INFO_EXTRA_VEL_Z            = "m/s"
   UNIT_XO_ORBIT_INFO_EXTRA_MEAN_KEPL_A      = "Semi-major axis (a) / mean"
   UNIT_XO_ORBIT_INFO_EXTRA_MEAN_KEPL_E      = "Eccentricity (e) / mean"
   UNIT_XO_ORBIT_INFO_EXTRA_MEAN_KEPL_I      = "Inclination (i) / mean"
   UNIT_XO_ORBIT_INFO_EXTRA_MEAN_KEPL_RA     = "Right ascension of the ascending node ( Ω ) / mean"
   UNIT_XO_ORBIT_INFO_EXTRA_MEAN_KEPL_W      = "Argument of perigee ( ω ) / mean"
   UNIT_XO_ORBIT_INFO_EXTRA_MEAN_KEPL_M      = "Mean anomaly (M) / mean"
   UNIT_XO_ORBIT_INFO_EXTRA_OSC_KEPL_A       = "Semi-major axis (a) / osculating"
   UNIT_XO_ORBIT_INFO_EXTRA_OSC_KEPL_E       = "Eccentricity (e) / osculating"
   UNIT_XO_ORBIT_INFO_EXTRA_OSC_KEPL_I       = "Inclination (i) / osculating"
   UNIT_XO_ORBIT_INFO_EXTRA_OSC_KEPL_RA      = "Right ascension of the ascending node ( Ω ) / osculating"
   UNIT_XO_ORBIT_INFO_EXTRA_OSC_KEPL_W       = "Argument of perigee ( ω ) / osculating"
   UNIT_XO_ORBIT_INFO_EXTRA_OSC_KEPL_M       = "Mean anomaly (M) / osculating"
   UNIT_XO_ORBIT_INFO_EXTRA_UTC_SMX          = "days (MJD2000)"
   UNIT_XO_ORBIT_INFO_EXTRA_NODAL_PERIOD     = "seconds"
   # --------------------------------------------

   # XO_ORBIT_EXTRA_choice_enum
  
   XO_ORBIT_EXTRA_NO_RESULTS                 = 0
   XO_ORBIT_EXTRA_GEOLOCATION                = 1
   XO_ORBIT_EXTRA_GEOLOCATION_D              = 2
   XO_ORBIT_EXTRA_GEOLOCATION_2D             = 4
   XO_ORBIT_EXTRA_GEOLOCATION_EXTRA          = 8
   XO_ORBIT_EXTRA_EARTH_FIXED_D              = 16
   XO_ORBIT_EXTRA_EARTH_FIXED_2D             = 32
   XO_ORBIT_EXTRA_SUN                        = 64
   XO_ORBIT_EXTRA_MOON                       = 128
   XO_ORBIT_EXTRA_OSCULATING_KEPLER          = 256
   XO_ORBIT_EXTRA_INERTIAL_AUX               = 512
   XO_ORBIT_EXTRA_DEP_ANX_TIMING             = 1024
   XO_ORBIT_EXTRA_DEP_MEAN_KEPLER            = 2048
   XO_ORBIT_EXTRA_ALL_RESULTS                = 4095

   XO_ORBIT_EXTRA_choice_enum = {
      "XO_ORBIT_EXTRA_NO_RESULTS"         => XO_ORBIT_EXTRA_NO_RESULTS,
      "XO_ORBIT_EXTRA_GEOLOCATION"        => XO_ORBIT_EXTRA_GEOLOCATION,
      "XO_ORBIT_EXTRA_GEOLOCATION_D"      => XO_ORBIT_EXTRA_GEOLOCATION_D,
      "XO_ORBIT_EXTRA_GEOLOCATION_2D"     => XO_ORBIT_EXTRA_GEOLOCATION_2D,
      "XO_ORBIT_EXTRA_GEOLOCATION_EXTRA"  => XO_ORBIT_EXTRA_GEOLOCATION_EXTRA,
      "XO_ORBIT_EXTRA_EARTH_FIXED_D"      => XO_ORBIT_EXTRA_EARTH_FIXED_D,
      "XO_ORBIT_EXTRA_EARTH_FIXED_2D"     => XO_ORBIT_EXTRA_EARTH_FIXED_2D,
      "XO_ORBIT_EXTRA_SUN"                => XO_ORBIT_EXTRA_SUN,
      "XO_ORBIT_EXTRA_MOON"               => XO_ORBIT_EXTRA_MOON,
      "XO_ORBIT_EXTRA_OSCULATING_KEPLER"  => XO_ORBIT_EXTRA_OSCULATING_KEPLER,
      "XO_ORBIT_EXTRA_INERTIAL_AUX"       => XO_ORBIT_EXTRA_INERTIAL_AUX,
      "XO_ORBIT_EXTRA_DEP_ANX_TIMING"     => XO_ORBIT_EXTRA_DEP_ANX_TIMING,
      "XO_ORBIT_EXTRA_DEP_MEAN_KEPLER"    => XO_ORBIT_EXTRA_DEP_MEAN_KEPLER,
      "XO_ORBIT_EXTRA_ALL_RESULTS"        => XO_ORBIT_EXTRA_ALL_RESULTS
   }
  
   # --------------------------------------------

   # XO_ORBIT_EXTRA_Model_MKO_dependant_enum;
 
   XO_ORBIT_EXTRA_DEP_NODAL_PERIOD        = 0
   XO_ORBIT_EXTRA_DEP_UTC_CURRENT_ANX     = 1
   XO_ORBIT_EXTRA_DEP_ORBIT_NUMBER        = 2
   XO_ORBIT_EXTRA_DEP_SEC_SINCE_ANX       = 3
   XO_ORBIT_EXTRA_DEP_MEAN_KEPL_A         = 4
   XO_ORBIT_EXTRA_DEP_MEAN_KEPL_E         = 5
   XO_ORBIT_EXTRA_DEP_MEAN_KEPL_I         = 6
   XO_ORBIT_EXTRA_DEP_MEAN_KEPL_RA        = 7
   XO_ORBIT_EXTRA_DEP_MEAN_KEPL_W         = 8
   XO_ORBIT_EXTRA_DEP_MEAN_KEPL_M         = 9
   XO_ORBIT_EXTRA_NUM_DEP_ELEMENTS        = 10

   XO_ORBIT_EXTRA_Model_MKO_dependant_enum = {
      "XO_ORBIT_EXTRA_DEP_NODAL_PERIOD"         => XO_ORBIT_EXTRA_DEP_NODAL_PERIOD,
      "XO_ORBIT_EXTRA_DEP_UTC_CURRENT_ANX"      => XO_ORBIT_EXTRA_DEP_UTC_CURRENT_ANX,
      "XO_ORBIT_EXTRA_DEP_ORBIT_NUMBER"         => XO_ORBIT_EXTRA_DEP_ORBIT_NUMBER,
      "XO_ORBIT_EXTRA_DEP_SEC_SINCE_ANX"        => XO_ORBIT_EXTRA_DEP_SEC_SINCE_ANX,
      "XO_ORBIT_EXTRA_DEP_MEAN_KEPL_A"          => XO_ORBIT_EXTRA_DEP_MEAN_KEPL_A,
      "XO_ORBIT_EXTRA_DEP_MEAN_KEPL_E"          => XO_ORBIT_EXTRA_DEP_MEAN_KEPL_E,
      "XO_ORBIT_EXTRA_DEP_MEAN_KEPL_I"          => XO_ORBIT_EXTRA_DEP_MEAN_KEPL_I,
      "XO_ORBIT_EXTRA_DEP_MEAN_KEPL_RA"         => XO_ORBIT_EXTRA_DEP_MEAN_KEPL_RA,
      "XO_ORBIT_EXTRA_DEP_MEAN_KEPL_W"          => XO_ORBIT_EXTRA_DEP_MEAN_KEPL_W,
      "XO_ORBIT_EXTRA_DEP_MEAN_KEPL_M"          => XO_ORBIT_EXTRA_DEP_MEAN_KEPL_M,
      "XO_ORBIT_EXTRA_NUM_DEP_ELEMENTS"         => XO_ORBIT_EXTRA_NUM_DEP_ELEMENTS
   }

   # XO_ORBIT_EXTRA_Model_independant_enum;

   XO_ORBIT_EXTRA_GEOC_LONG                     = 0
   XO_ORBIT_EXTRA_GEOD_LAT                      = 1
   XO_ORBIT_EXTRA_GEOD_ALT                      = 2
   XO_ORBIT_EXTRA_GEOC_LONG_D                   = 3
   XO_ORBIT_EXTRA_GEOD_LAT_D                    = 4
   XO_ORBIT_EXTRA_GEOD_ALT_D                    = 5
   XO_ORBIT_EXTRA_GEOC_LONG_2D                  = 6
   XO_ORBIT_EXTRA_GEOD_LAT_2D                   = 7
   XO_ORBIT_EXTRA_GEOD_ALT_2D                   = 8
   XO_ORBIT_EXTRA_RAD_CUR_PARALLEL_MERIDIAN     = 9
   XO_ORBIT_EXTRA_RAD_CUR_ORTHO_MERIDIAN        = 10
   XO_ORBIT_EXTRA_RAD_CUR_ALONG_GROUNDTRACK     = 11
   XO_ORBIT_EXTRA_NORTH_VEL                     = 12
   XO_ORBIT_EXTRA_EAST_VEL                      = 13
   XO_ORBIT_EXTRA_MAG_VEL                       = 14
   XO_ORBIT_EXTRA_AZ_VEL                        = 15
   XO_ORBIT_EXTRA_NORTH_ACC                     = 16
   XO_ORBIT_EXTRA_EAST_ACC                      = 17
   XO_ORBIT_EXTRA_GROUNDTRACK_ACC               = 18
   XO_ORBIT_EXTRA_AZ_ACC                        = 19
   XO_ORBIT_EXTRA_SAT_ECLIPSE_FLAG              = 20
   XO_ORBIT_EXTRA_SZA                           = 21
   XO_ORBIT_EXTRA_MLST                          = 22
   XO_ORBIT_EXTRA_TLST                          = 23
   XO_ORBIT_EXTRA_TRUE_SUN_RA                   = 24
   XO_ORBIT_EXTRA_TRUE_SUN_DEC                  = 25
   XO_ORBIT_EXTRA_TRUE_SUN_SEMIDIAM             = 26
   XO_ORBIT_EXTRA_MOON_RA                       = 27
   XO_ORBIT_EXTRA_MOON_DEC                      = 28
   XO_ORBIT_EXTRA_MOON_SEMI_DIAM                = 29
   XO_ORBIT_EXTRA_MOON_AREA_LIT                 = 30
   XO_ORBIT_EXTRA_OSC_KEPL_A                    = 31
   XO_ORBIT_EXTRA_OSC_KEPL_E                    = 32
   XO_ORBIT_EXTRA_OSC_KEPL_I                    = 33
   XO_ORBIT_EXTRA_OSC_KEPL_RA                   = 34
   XO_ORBIT_EXTRA_OSC_KEPL_W                    = 35
   XO_ORBIT_EXTRA_OSC_KEPL_M                    = 36
   XO_ORBIT_EXTRA_ORBIT_RAD                     = 37
   XO_ORBIT_EXTRA_RADIAL_ORB_VEL                = 38
   XO_ORBIT_EXTRA_TRANS_ORB_VEL                 = 39
   XO_ORBIT_EXTRA_ORB_VEL_MAG                   = 40
   XO_ORBIT_EXTRA_RA_SAT                        = 41
   XO_ORBIT_EXTRA_DEC_SAT                       = 42
   XO_ORBIT_EXTRA_EARTH_ROTATION_ANGLE          = 43
   XO_ORBIT_EXTRA_RA_SAT_D                      = 44
   XO_ORBIT_EXTRA_RA_SAT_2D                     = 45
   XO_ORBIT_EXTRA_OSC_TRUE_LAT                  = 46
   XO_ORBIT_EXTRA_OSC_TRUE_LAT_D                = 47
   XO_ORBIT_EXTRA_OSC_TRUE_LAT_2D               = 48
   XO_ORBIT_EXTRA_NUM_INDEP_ELEMENTS            = 49

   XO_ORBIT_EXTRA_GEOC_LONG_UNIT          = "deg / Geocentric longitude of satellite and SSP (EF frame)  => [0,360)" 
   XO_ORBIT_EXTRA_GEOD_LAT_UNIT           = "deg / Geodetic latitude of satellite and SSP (EF frame)   => [-90,+90]"
   XO_ORBIT_EXTRA_GEOD_ALT_UNIT           = "m / Geodetic altitude of the satellite (EF frame)"
   # --------------------------------------------
   
   # xo_osv_compute return OSV array mapping
   # OSV array mapping

   RB_OSV_IDX_POS_X = 0
   RB_OSV_IDX_POS_Y = 1
   RB_OSV_IDX_POS_Z = 2
   RB_OSV_IDX_VEL_X = 3
   RB_OSV_IDX_VEL_Y = 4
   RB_OSV_IDX_VEL_Z = 5
   RB_OSV_IDX_ACC_X = 6
   RB_OSV_IDX_ACC_Y = 7
   RB_OSV_IDX_ACC_Z = 8

   RB_OSV_POS_UNIT = "m"
   RB_OSV_VEL_UNIT = "m/s"
   RB_OSV_ACC_UNIT = "m/s^2"

end

## ==============================================================================
