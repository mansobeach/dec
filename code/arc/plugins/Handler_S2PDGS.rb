#!/usr/bin/env ruby

#########################################################################
###
### ===       
###
### === Written by Borja Lopez Fernandez
###
### === Casale & Beach
### 
###
###
#########################################################################

# This class allows minarc to handle S2PDGS files:
#
# S2A_OPER_REP_OPDPC__SGS__20170214T113527_V20170214T080018_20170214T080336.EOF
# S2__OPER_DEC_F_RECV_2BOA_20200205T183117_V20200205T183117_20200205T183117.xml
# S2__OPER_DEC_F_RECV_2BOA_20200205T183117_V20200205T183117_20200205T183117_SUPER_TCI.xml
# S2__OPER_DEC_F_RECV_2BOA_20200205T183117_V20200205T183117_20200205T183117_S2PDGS.xml
# S2__OPER_REP_ARC____SGS__20170214T105715_V20170214T030309_20170214T031438_A008609_T50RKS.EOF
# S2A_OPER_MPL__NPPF__20170217T110000_20170304T140000_0001.TGZ
# S2A_OPER_REP__SUP___20151219T193158_99999999T999999_0001.EOF
# S2A_OPER_REP_SUCINV_MPC__20150625T235026_20150624T232135_20150625T232135.ZIP
# S2A_OPER_GIP_PROBAS_MPC__20170425T000205_V20150622T000000_20200101T000000_B00.TGZ
# S2__OPER_REP_OPDHUS_DHUS_20180404T165255.xml
# S2__OPER_REP_ARC__A_UPA__20170517T150557_V20170518T001000_21000101T000000_<pid>.EOF
# DEC_OPER_REPDHUS_S1_AUIP_20210325T201708_V20210325T173000_112_000.json (70 character)
# - Non compressed files (.EOF .xml, others) are natively managed as 7z (thus apply compression)
# - Compressed files with extension zip, tgz, 7z are handled without further compression into 7z
#
#
# NOT SUPPORTED !! Fenomenal fake dates ! 
# S2__OPER_REP_ARC__A_UPA__20170427T090404_V20170418T020822_99999999T999999_26869.EOF
#
#

require 'filesize'

require 'cuc/Converters'

include CUC::Converters


class Handler_S2PDGS

   @type                = ""
   @filename            = ""
   @filename_original   = nil
   @validated           = false
   @start               = nil
   @stop                = nil 
   @generation_date     = nil
   @full_path_filename  = ""
   @size                = 0
   @size_in_disk        = 0

   attr_reader :archive_path, :size, :size_in_disk, :size_original, :type, :filename, :filename_original, :start, :stop, :str_start, :str_stop

   ## -----------------------------------------------------------

   ## Class constructor
   
   ## Name now must be a full_path one
   def initialize (name, destination = nil, args = {})
      
      if name[0,1] != '/' then
         @bDecodeNameOnly = true
      else
         @bDecodeNameOnly = false
      end
      
      archRoot       = ENV['MINARC_ARCHIVE_ROOT']
      @filename      = File.basename(name, ".*")
      @filename_original   = File.basename(name)
      @archive_path  = ""
      @validated     = false

      # ----------------------------------------------------
      #
      # DEC_OPER_REPDHUS_S1_AUIP_20210325T201708_V20210325T173000_<variable>
      
      if @filename.length > 57 and @filename.slice(0,3) == "DEC" &&
         @filename.slice(41,1) == "V" &&
         @filename.slice(3,1) == "_" &&
         @filename.slice(8,1) == "_" then
         @str_start        = @filename.slice(42, 15)
         @str_stop         = @filename.slice(25, 15)    
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(42, 15))
         @stop             = @generation_date         
         @validated        = true
      end 
      # ----------------------------------------------------


      # ----------------------------------------------------
      # E2ESPM Analytics Reports 
      if @filename.length == 72 then
         @str_start        = @filename.slice(41, 15)
         @str_stop         = @filename.slice(57, 15)
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(41, 15))
         @stop             = self.str2date(@filename.slice(57, 15))
         
         if isTypeAnalytic?(@type) == false then
            system("\\rm -f #{name}")
            puts "Deleted #{name}" 
            exit(99)
         end
        
         @type             = "REP_E2ESPM"
         @validated        = true
      end 
      # ----------------------------------------------------

      # S2A_OPER_REP_OPDPC__SGS__20170214T113527_V20170214T080018_20170214T080336.EOF
      # S2__OPER_REP_ARC____SGS__20170214T105715_V20170214T030309_20170214T031438_A008609_T50RKS.EOF
      # S2A_OPER_GIP_PROBAS_MPC__20170425T000205_V20150622T000000_20200101T000000_B00.TGZ

      if @filename.length == 73 or @filename.length == 88 or @filename.length == 77 then
         @str_start        = @filename.slice(42, 15)
         @str_stop         = @filename.slice(58, 15)      
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(42, 15))
         @stop             = self.str2date(@filename.slice(58, 15))         
         @validated        = true
      end 
     
      # ----------------------------------------------------     
         
      if @filename.length == 56 then
         @str_start        = @filename.slice(20, 15)
         @str_stop         = @filename.slice(36, 15)      
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
      
      # ----------------------------------------------------
      
      # S2__OPER_REP_OPDHUS_DHUS_20180404T165255
      if @filename.length == 40 then
         @str_start        = @filename.slice(25, 15)
         @str_stop         = @filename.slice(25, 15)            
         @type             = @filename.slice(9,10)         
         @start            = self.str2date(@filename.slice(25, 15))
         @generation_date  = @start
         @stop             = @start
         @validated        = true
      end

      # ----------------------------------------------------
      
      # S2__OPER_REP_ARC__A_UPA__20170517T150557_V20170518T001000_21000101T000000_<pid>.EOF
      # S2__OPER_REP_ARC__A_UPA__20170505T190559_V20170322T000000_21000101T000000_343.EOF
      # S2__OPER_REP_ARC__A_UPA__20170505T190530_V20170505T000000_20180504T000000_6949.EOF
      # S2__OPER_REP_ARC__A_UPA__20170427T090404_V20170418T020822_99999999T999999_26864.EOF
      
      if @filename.include?("REP_ARC__A") == true then
         @str_start        = @filename.slice(42, 15)
         @str_stop         = @filename.slice(58, 15)      
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(42, 15))
         @stop             = self.str2date(@filename.slice(58, 15))         
         @validated        = true      
      end
      
      # ----------------------------------------------------
      
      # S2__OPER_DEC_F_RECV_2BOA_20200205T183117_V20200205T183117_20200205T183117_SUPER_TCI.xml
      # S2__OPER_DEC_F_RECV_2BOA_20200205T183117_V20200205T183117_20200205T183117_S2PDGS.xml
      
      if @filename.length > 73 and @filename.slice(3,1) == "_" and @filename.slice(8,1) == "_" &&
         @filename.slice(19,1) == "_" and @filename.slice(24,1) == "_" and @filename.slice(40,1) == "_" &&
         @filename.slice(41,1) == "V" 
      then
         @str_start        = @filename.slice(42, 15)
         @str_stop         = @filename.slice(58, 15)      
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(42, 15))
         @stop             = self.str2date(@filename.slice(58, 15))         
         @validated        = true      
      end
      
      # ----------------------------------------------------
         
      if @validated == false then
         puts @filename.length
         puts "#{@filename} not supported by Handler_S2PDGS !"
         puts
         exit(99)
      end

      # ----------------------------------------------------

      if @bDecodeNameOnly == true then
         return
      end

      # ----------------------------------------------------


      @archive_path  = "#{archRoot}/#{@type}/#{Date.today.strftime("%Y")}/#{Date.today.strftime("%m")}/#{Date.today.strftime("%d")}"

      @size_original = File.size(name)

      if File.extname(name).downcase != ".zip" and 
         File.extname(name).downcase != ".tgz" and 
         File.extname(name).downcase != ".7z" then
         compressFile(name)
      else
         @full_path_filename  = name         
      end

      @size          = File.size(@full_path_filename)
      result         = `du -hs #{@full_path_filename}`
      
      begin
         @size_in_disk  = Filesize.from("#{result.split(" ")[0]}iB").to_int
      rescue Exception => e
         @size_in_disk  = 0
      end

#      if args[:bDeleteSource] == true then
#         File.delete(@full_path_filename)
#      end

   end

   # ------------------------------------------------------------

   def isValid
      return @validated
   end

   # ------------------------------------------------------------

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
   
   # ------------------------------------------------------------
   
   def fileName
      return @full_path_filename
   end
   # ------------------------------------------------------------


private

   ## -----------------------------------------------------------

   def compressFile(full_path_name)
      filename       = File.basename(full_path_name, ".*")
      full_path      = File.dirname(full_path_name)
      
      if File.exist?("#{full_path}/#{filename}.7z") == true then
         @full_path_filename  = "#{full_path}/#{filename}.7z"
         return
      end
      
      # Ubuntu  
      cmd = "7za a #{full_path}/#{filename}.7z #{full_path_name} > /dev/null"
      
      # MacOS       
      # cmd = "7za a #{full_path}/#{filename}.7z #{full_path_name} -sdel"
     
      ret = system(cmd)
      
      if ret == false then
         puts "Fatal Error in Handler_S2PDGS::compressFile"
         puts
         puts cmd
         puts
         puts "Deleting eventual previous compressed file #{full_path}/#{filename}.7z"
         puts
         File.delete("#{full_path}/#{filename}.7z")
         exit(99)
      else
         File.delete(full_path_name)
      end
            
      @full_path_filename  = "#{full_path}/#{filename}.7z"
            
   end

   ## -----------------------------------------------------------
   ##
   ## E2ESPM analytic reports
   
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
            puts "Handler_S2PDGS::isTypeAnalytic? #{type} not registered"
            puts
            exit(99)
         
      end
   end
   ## -----------------------------------------------------------
   
end
