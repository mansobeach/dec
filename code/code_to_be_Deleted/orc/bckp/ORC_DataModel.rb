#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ORC_DatabaseModel class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === MDS-LEGOS -> ORC Component
# 
# CVS: $Id: ORC_DataModel.rb,v 1.9 2008/12/17 17:47:57 decdev Exp $
#
# module ORC
#
#########################################################################


require "rubygems"
require "active_record"

dbAdapter   = ENV['ORC_DB_ADAPTER']
dbName      = ENV['ORC_DATABASE_NAME']
dbUser      = ENV['ORC_DATABASE_USER']
dbPass      = ENV['ORC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)

#=====================================================================

class TriggerProduct < ActiveRecord::Base
   validates_presence_of   :filename
   validates_uniqueness_of :filename
   validates_presence_of   :filetype  
   validates_presence_of   :detection_date
   validates_presence_of   :sensing_start
   validates_presence_of   :sensing_stop
   validates_presence_of   :runtime_status
   validates_presence_of   :initial_status
end

#=====================================================================
# Class OrchestratorQueue tables

class OrchestratorQueue < ActiveRecord::Base
   set_table_name :orchestrator_queue
   set_primary_key :trigger_product_id

   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"
   #----------------------------------------------   
   
   def OrchestratorQueue.getQueuedFiles
      arrFiles     = Array.new
      triggerFiles = TriggerProduct.find(:all)
      queuedFiles  = OrchestratorQueue.find(:all)

      triggerFiles.each{|triggerFile|
         queuedFiles.each{|queuedFile|
            if triggerFile.id == queuedFile.trigger_product_id then
               arrFiles << triggerFile
            end
         }         
      }
      return arrFiles
   end
   #----------------------------------------------   

end

#=====================================================================

class FailingTriggerProduct < ActiveRecord::Base
   set_primary_key :trigger_product_id

   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"

end

#=====================================================================

class SuccessfulTriggerProduct < ActiveRecord::Base
   set_primary_key :trigger_product_id
   
   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"
end

#=====================================================================

class ObsoleteTriggerProduct < ActiveRecord::Base
   set_primary_key :trigger_product_id   

   belongs_to  :trigger_products,
               :class_name    => "TriggerProduct",
               :foreign_key   => "trigger_product_id"
   
   #----------------------------------------------   
   
   def ObsoleteTriggerProduct.getObsoleteFiles
      arrFiles       = Array.new
      triggerFiles   = TriggerProduct.find(:all)
      obsoleteFiles  = ObsoleteTriggerProduct.find(:all)

      triggerFiles.each{|triggerFile|
         obsoleteFiles.each{|queuedFile|
            if triggerFile.id == queuedFile.trigger_product_id then
               arrFiles << triggerFile
            end
         }         
      }
      return arrFiles
   end   
   #----------------------------------------------   

end

#=====================================================================

class Pending2QueueFile < ActiveRecord::Base
   set_table_name :pending2queue_files
   validates_presence_of   :filename
   validates_presence_of   :detection_date
end

#=====================================================================

class ProductionTimeline < ActiveRecord::Base
   validates_presence_of   :file_type
   validates_presence_of   :sensing_start
   validates_presence_of   :sensing_stop

   def ProductionTimeline.addSegment(type, start, stop)

      s_start = start.strftime("%Y%m%d%H%M%S")
      s_stop  = stop.strftime("%Y%m%d%H%M%S")

      #look for a timeline that completely covers the new segment
      arrTimeLines = ProductionTimeline.find(:all, :conditions=> "file_type = '#{type}' AND (sensing_start <= #{s_start} AND sensing_stop >= #{s_stop})")

      if (arrTimeLines.size > 0) then
         puts "INFO : This timeline is already present for #{type}... :-|"
         return
      end

      #look for timeline bounds inside the new segment's time interval
      arrTimeLines = ProductionTimeline.find(:all, :conditions=> "file_type = '#{type}' AND ((sensing_start >= #{s_start} AND sensing_start <= #{s_stop}) OR (sensing_stop >= #{s_start} AND sensing_stop <= #{s_stop}))")

      ProductionTimeline.transaction do

         if (arrTimeLines.size > 0) then
   
            arrTimeLines.each{|seg|
               #merge
               seg.destroy
               
               tmp = seg.sensing_start
               seg_start = DateTime.new(tmp.strftime("%Y").to_i, tmp.strftime("%m").to_i, tmp.strftime("%d").to_i, tmp.strftime("%H").to_i, tmp.strftime("%M").to_i, tmp.strftime("%S").to_i)
               tmp = seg.sensing_stop
               seg_stop  = DateTime.new(tmp.strftime("%Y").to_i, tmp.strftime("%m").to_i, tmp.strftime("%d").to_i, tmp.strftime("%H").to_i, tmp.strftime("%M").to_i, tmp.strftime("%S").to_i)

               if (start > seg_start) then
                  start = seg_start
               end

               if (stop < seg_stop) then
                  stop = seg_stop
               end      
            }

         end

         newLine = ProductionTimeline.new(:file_type => type, :sensing_start => start, :sensing_stop => stop)

         newLine.save!

      end
   end


   def ProductionTimeline.searchAllWithinInterval(filetype, start, stop, bIncStart=false, bIncEnd=false)
      arrFiles    = Array.new
      arrResult   = Array.new

      # if no filetype is specified, retrieve everything
      if filetype != nil and filetype != "" then
         arrFiles = ProductionTimeline.find_all_by_file_type(filetype)
      else
         return nil
      end

      # if start and stop criteria are defined, filter files
      if start != nil and stop != nil and start != "" and stop != "" then

         arrFiles.each{|aFile|
           
            # if the file is missing a valid validity interval, discard it
            if aFile.sensing_start == nil or aFile.sensing_stop == nil then
               next
            end

            # patch because accessors return a Time object instead of DateTime
            file_start = DateTime.parse(aFile.sensing_start.strftime("%Y%m%dT%H%M%S"))
            file_stop  = DateTime.parse(aFile.sensing_stop.strftime("%Y%m%dT%H%M%S"))

            # if the file's validity is entirely outside the bounds, discard it
            if (file_stop < start) or (file_start > stop) then
               next
            end

            # strict validity check on lower bound
            if (file_start < start) and (bIncStart == false) then
               next
            end

            # strict validity check on upper bound
            if (file_stop > stop) and (bIncEnd == false) then
               next
            end

            arrResult << aFile

         }

      else
         arrFiles.each{|aFile|
            
            arrResult.push(aFile)
         }
      end

      return arrResult

   end

end
#=====================================================================

class RunningJob < ActiveRecord::Base
end

#=====================================================================

class OrchestratorMessage < ActiveRecord::Base
   set_table_name :orchestrator_messages
end

class MessageParameter < ActiveRecord::Base
   set_table_name :message_parameters

   belongs_to  :orchestrator_messages,
               :class_name    => "OrchestratorMessage",
               :foreign_key   => "orchestrator_message_id"

end

#=====================================================================
