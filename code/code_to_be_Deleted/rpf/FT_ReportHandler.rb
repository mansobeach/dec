#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #FT_ReportHandler.rb
#          
# Written by DEIMOS Space S.L. (paat)
#
# RPF
# 
# CVS:
#  $Id: FT_ReportHandler.rb,v 1.1 2007/04/09 13:18:08 decdev Exp $
#
#########################################################################

require 'cuc/DirUtils'

# This class provides methods for management report file and insert 
# in archive.
# 
# It implements methods as get name report incoming files or 
# outgoing report file, moreover put this reports in archive;
# Call program to put file in repository of files and insert
# changes on data base.
# RPF Inventory (Database).

class FT_ReportHandler

   include CUC::DirUtils

private
   @nROP=0
   @entity=nil
public

   def initialize(nROP,entity=nil)
      @nROP=nROP
      @entity=entity 
   end
  
   def getOutReportName
     reportPath=expandPathValue("$FTPROOT/_Reports_/outgoing")
     if (@nROP.to_i!=0) then
       fileName="FT_REP.#{@nROP}"
     else
       fileName="FT_REP.Emergency"
     end
     checkDirectory(reportPath)
     reportName=File.join(reportPath,fileName)
     return reportName
  end
  
  
   def getInReportName
     reportPath=expandPathValue("$FTPROOT/_Reports_/incoming")
     fileName="FT_REP.#{@entity}"
     checkDirectory(reportPath)
     reportName=File.join(reportPath,fileName)
     return reportName
   end

   def putOutReport
     if (ENV['RPFBIN'])
       enviroment=ENV['RPFBIN']
       command=%Q{#{enviroment}}
       command<<%Q{/put_report.bin -R #{@nROP} -r #{getOutReportName}}
       if (@nROP.to_i!=0)
          command<<%Q{ -o }
       else
          command<<%Q{ -e }
       end
       system(command);
     else
       puts"Environment Variable $RPFBIN is not defined!"
     end
   end
   
   def putInReport
     if (ENV['RPFBIN'])
       enviroment=ENV['RPFBIN']
       command=%Q{#{enviroment}}
       command<<%Q{/put_report.bin -R #{@nROP} -r #{getInReportName} -i }
       system(command);
     else
       puts "Environment Variable $RPFBIN is not defined!"
     end
   end
   
   
   def headerReport
     if(@nROP.to_i!=9) then
         file=File.open(getOutReportName(),File::RDWR|File::CREAT)
     else
         file=File.open(getInReportName(),File::RDWR|File::CREAT) 
     end
     if (file!=nil) then
        file.seek(0,IO::SEEK_SET)
        file.write("\n\n\n")
        file.puts("File Transfer Report")
        file.puts("===============================================================")
        file.puts("Date:  #{file.atime()} ")
        if (@entity==nil) then
           if (@nROP.to_i!=0)
              file.puts("ROP version: #{@nROP} ")
           else
              file.puts("Mode Emergency ")
           end               
        else
           file.puts("Entity name: #{@entity} ")
        end
        file.puts("===============================================================")

        # Transfer log information is appended after this line
        file.puts("\n\n =Transfer Log ================================================") 
        file.close()
     end
   end

end
