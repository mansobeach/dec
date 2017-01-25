#!/usr/bin/env ruby

# == Synopsis
#
# This class writes an XML file with the content of all the files handled by DEC
# falling under a certain time window interval.
#
# If no time window is specified, the report coverage will correspond to yesterday
#
# == Usage
# createTimeWindowReport.rb -t <table value> -b <start date> -e <stop date> [ -d <dir> ] [ -n <namespace> ]
#
#   --"table",     "-t",    possible values are 'send','receive'
#   --"class",     "-c",    class of the report
#   --"begin",     "-b",    start time
#   --"end",       "-e",    stop time
#   --"directory", "-d",    destination of the file generated
#   --"namespace", "-n",    namespace to be added to the report generated
#   --help      shows this help
#   --usage     shows the usage
#
# == Author
# Deimos-Space S.L. (algk)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: createTimeWindowReport.rb,v 1.4 2014/07/14 16:17:18 algs Exp $
#
#########################################################################

require 'rubygems'
require 'getoptlong'

require 'ctc/ListWriterByTimeWindow'
require 'dcc/ReadConfigDCC'


# Global variables
@dateLastModification = "$Date: 2007/02/06 13:38:56 $"   # to keep control of the last modification
                                     # of this script
@verboseMode      = 0                # execution in verbose mode
@mnemonic         = ""
@bShowMnemonics   = false

# MAIN script function
def main   
   
      directory         = '.'
      fileClass         = 'OPER'
      start             = ''
      stop              = ''
      table             = ''
      namespace         = ''
      schema            = ''
      table_values      = Array['send', 'receive']
     
    
      opts = GetoptLong.new(
        ["--table",     "-t",    GetoptLong::REQUIRED_ARGUMENT],
        ["--class",     "-c",    GetoptLong::REQUIRED_ARGUMENT],
        ["--begin",     "-b",    GetoptLong::REQUIRED_ARGUMENT],
        ["--end",       "-e",    GetoptLong::REQUIRED_ARGUMENT],
        ["--directory", "-d",    GetoptLong::REQUIRED_ARGUMENT],
        ["--namespace", "-n",    GetoptLong::REQUIRED_ARGUMENT],
        ["--schema",    "-s",    GetoptLong::REQUIRED_ARGUMENT],
        ["--usage",     "-U",    GetoptLong::NO_ARGUMENT],
        ["--help",      "-h",    GetoptLong::NO_ARGUMENT]
      )
    
      begin
         opts.each do |opt, arg|
            case opt      
               when "--table"          then table             =  arg.to_s
               when "--class"          then fileClass         =  arg.to_s
               when "--begin"          then start             =  arg.to_s
               when "--end"            then stop              =  arg.to_s
               when "--directory"      then directory         =  arg.to_s
               when "--namespace"      then namespace         =  arg.to_s
               when "--schema"         then schema            =  arg.to_s
			      when "--help"           then usage
	            when "--usage"          then usage
            end
         end
      rescue Exception
         exit(99)
      end

      if start.empty? or stop.empty? then
#          puts
#          puts "Start and Stop dates are mandatory"
#          puts
#          puts usage
#          exit (99)
         start = Date.yesterday.to_date.beginning_of_day
         stop  = Date.yesterday.to_date.end_of_day
      else
         begin
            # start = start.to_datetime
            # stop  = stop.to_datetime
         
            start = start.to_date.beginning_of_day
            stop  = stop.to_date.end_of_day
         rescue Exception => e
            puts e
            exit(99)
         end
      end

      if !table_values.include?(table) or table.empty? then
         puts
         puts "Invalid table : '#{table}' !"
         usage 
      end
  
      satPrefix   = DCC::ReadConfigDCC.instance.getSatPrefix
      prjName     = DCC::ReadConfigDCC.instance.getProjectName
      prjID       = DCC::ReadConfigDCC.instance.getProjectID
      mission     = DCC::ReadConfigDCC.instance.getMission
      type        = DCC::ReadConfigDCC.instance.getReportConfig("RETRIEVEDFILES")[:fileType]


#       type = nil
# 
#       case table      
#          when 'send'       then
#             type='REP_SSDLR_'
#          when 'receive'   then
#             type='REP_SSREC_'
#       end



      if fileClass.size != 4 then
         puts "File class must have 4 chars"
         exit (1)
      end

      if !FileTest.directory?(directory) then
         puts "Specified directory does not exist. Using current dir"
         directory = '.'
      end

      writer = CTC::ListWriterByTimeWindow.new(directory, table , start, stop, fileClass, type)
      writer.setup(satPrefix, prjName, prjID, mission, namespace, schema)
      writer.writeData()

      puts "Created Report File #{writer.getFilename}"
   
   
end

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -26 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------




#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
