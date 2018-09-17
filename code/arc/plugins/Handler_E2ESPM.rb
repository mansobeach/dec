#!/usr/bin/env ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

# This plugin allows minarc to handle E2ESPM archive.
#
# This plug-in leaves untouched the archived files 
# and it respects source directory tree 
#
# It has been conceived as a wrapper to the native E2ESPM archive
#
#
# S2A_OPER_REP_OPDPC__SGS__20170214T113527_V20170214T080018_20170214T080336.EOF
# S2__OPER_REP_ARC____SGS__20170214T105715_V20170214T030309_20170214T031438_A008609_T50RKS.EOF
# S2A_OPER_MPL__NPPF__20170217T110000_20170304T140000_0001.TGZ
# S2A_OPER_REP__SUP___20151219T193158_99999999T999999_0001.EOF
# S2A_OPER_REP_SUCINV_MPC__20150625T235026_20150624T232135_20150625T232135.ZIP
#

require 'filesize'

require 'cuc/Converters'

include CUC::Converters


class Handler_E2ESPM

   @type                = ""
   @filename            = ""
   @validated           = false
   @start               = nil
   @stop                = nil 
   @generation_date     = nil
   @full_path_filename  = ""
   @size                = 0
   @size_in_disk        = 0

   attr_reader :archive_path, :size, :size_in_disk, :size_original

   #-------------------------------------------------------------

   # Class constructor
   
   # Name now must be a full_path one
   def initialize (name, destination = nil, args = {})
      archRoot             = ENV['MINARC_ARCHIVE_ROOT']
      @filename            = File.basename(name, ".*")
      @archive_path        = File.dirname(name)
      @full_path_filename  = name   
      @validated           = false

      # ----------------------------------------------------
      # E2ESPM Analytics Reports 
      if @filename.length == 72 then
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(41, 15))
         @stop             = self.str2date(@filename.slice(57, 15))
         
#          if isTypeAnalytic?(@type) == false then
#             system("\\rm -f #{name}")
#             puts "Deleted #{name}" 
#             exit(99)
#          end
         
         @type             = "REP_E2ESPM"
         @validated        = true
      end 
      # ----------------------------------------------------

      if @filename.length == 73 or @filename.length == 88 then
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(42, 15))
         @stop             = self.str2date(@filename.slice(58, 15))         
         @validated        = true
      end 
     
      # ----------------------------------------------------     
         
      if @filename.length == 56 then
         @type             = @filename.slice(9,10)         
         @start            = self.str2date(@filename.slice(20, 15))
         @generation_date  = @start
         
         if @filename.slice(36, 15) == "99999999T999999" then
            @stop = DateTime.new(2100,1,1)
         else
            @stop = self.str2date(@filename.slice(36, 15))
         end
         @validated        = true
      end          
         
      if @validated == false then
         puts @filename.length
         puts "#{@filename} not supported by Handler_E2ESPM !"
         puts
         exit(99)
      end

      @size_original = File.size(name)

      @size          = File.size(@full_path_filename)
      result         = `du -hs #{@full_path_filename}`
      @size_in_disk  = Filesize.from("#{result.split(" ")[0]}iB").to_int

   end

   #-------------------------------------------------------------

   def isValid
      return @validated
   end

   #-------------------------------------------------------------

   def fileType
      return @type
   end

   #-------------------------------------------------------------

   def start_as_dateTime
      return @start
   end

   #-------------------------------------------------------------

   def stop_as_dateTime
      return @stop
   end

   #-------------------------------------------------------------

   def generationDate
      return @generation_date
   end
   
   #-------------------------------------------------------------
   
   def fileName
      return @full_path_filename
   end
   #-------------------------------------------------------------


private


   #-------------------------------------------------------------

   # E2ESPM analytic reports
   #
   # method likely to not be needed
   
   def isTypeAnalytic?(type)

      case type
                 
         when "REP_E2EMPL" then return true
         
         # REP_ACQSCH
         
         when "REP_ACQSCH" then return true
         
         when "REP_AOCPRO" then return true
         
         when "REP_ARCSUM" then return true
         
         when "REP_DATCOM" then return true
         
         when "REP_DARCCO" then return true
         
         when "REP_SUCINV" then return true
         
         when "REP_DAGSAC" then return true
         
         when "REP_DAMCOM" then return true
         
         when "REP_DATARC" then return true
         
         when "REP_DATARI" then return true
         
         when "REP_DATINX" then return true
         
         when "REP_DFEPCO" then return true
         
         when "REP_DHUSCO" then return true
         
         when "REP_E2EAC2" then return true
         
         when "REP_E2EACB" then return true
         
         when "REP_E2EACQ" then return true
         
         when "REP_E2EAVA" then return true
         
         when "REP_E2EAVB" then return true
         
         when "REP_E2EDAR" then return true
         
         when "REP_E2EL0C" then return true
         
         when "REP_E2EL1C" then return true
         
         when "REP_E2EL1C" then return true
         
         when "REP_E2EL1T" then return true
         
         when "REP_E2ELTD" then return true
         
         when "REP_E2EMPX" then return true
         
         when "REP_E2ETIM" then return true
         
         when "REP_EOBTRN" then return true
         
         when "REP_HKTARC" then return true
         
         when "REP_HKTCIR" then return true
         
         when "REP_HKTWOR" then return true
         
         when "REP_INGSTA" then return false
         
         when "REP_INGVAL" then return false
         
         when "REP_L0DARC" then return true
         
         when "REP_L0DCIR" then return true
         
         when "REP_L1BARC" then return true
         
         when "REP_L1ACIR" then return true
         
         when "REP_L1BCIR" then return true
         
         when "REP_L1CARC" then return true
         
         when "REP_L1CCIR" then return true
         
         when "REP_LOSTDA" then return true
         
         when "REP_MACOPR" then return true
         
         when "REP_MISCON" then return true
         
         when "REP_MISCOR" then return true
         
         when "REP_MMFUCO" then return true
         
         when "REP_MEMEVO" then return true
         
         when "REP_MEMEVB" then return true
         
         when "REP_MONMAC" then return false
         
         when "REP_OCPAOC" then return true
         
         when "REP_PODCIR" then return true
         
         when "REP_PREORW" then return true
         
         when "REP_PROTIM" then return true
         
         when "REP_PROWOB" then return true
         
         when "REP_PROWOR" then return true
         
         when "REP_PROWOS" then return true
         
         when "REP_DATIDS" then return true
         
         when "REP_QUADIS" then return true
         
         when "REP_QUATIM" then return true
         
         when "REP_TIMLIN" then return true
         
         when "REP_SADARC" then return true
         
         when "REP_SADCIR" then return true
         
         when "REP_SATCOM" then return true
         
         when "REP_SUCINS" then return false
         
         # Ingestion Error Stamps
         when "REP_SUCINV" then return false
         
         when "REP_TLEWOR" then return true
         
         when "REP_TIMLIB" then return true
         
         else
            puts
            puts "Handler_E2ESPM::isTypeAnalytic? #{type} not registered"
            puts
            exit(99)
         
      end
   end
   #-------------------------------------------------------------
   
end
