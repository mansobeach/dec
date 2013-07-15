#!/usr/bin/env ruby

require 'cuc/CheckerProcessUniqueness'  

fork{

   sleep(5)

}


   oldProcess = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true) 


 #  oldProcess = CUC::CheckerProcessUniqueness.new("KAKO", "", true) 

   # oldProcess.setDebugMode

   arrPids = oldProcess.getAllRunningProcesses.reverse

   puts arrPids
   puts

   arrPids.each{|pid|
      puts pid
      if pid.to_s.length < 4 then
         next
      end
         puts "Killing process #{pid}"
      begin  
         Process.kill(9, pid.to_i)
      rescue Exception => e
         puts e.to_s
      end
      sleep(1)
   }
