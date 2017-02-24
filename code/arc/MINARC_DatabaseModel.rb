#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MINARC_DatabaseModel class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: MINARC_DatabaseModel.rb,v 1.12 2008/10/10 16:18:30 decdev Exp $
#
# module MINARC
#
#########################################################################

require 'rubygems'
require 'active_record'

dbAdapter   = ENV['MINARC_DB_ADAPTER']
dbName      = ENV['MINARC_DATABASE_NAME']
dbUser      = ENV['MINARC_DATABASE_USER']
dbPass      = ENV['MINARC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass, :timeout  => 1000)

class ArchivedFile < ActiveRecord::Base
   validates_presence_of   :filename
   validates_uniqueness_of :filename
   validates_presence_of   :filetype
   validates_presence_of   :archive_date


   #--------------------------------------------------------

   def ArchivedFile.searchAllWithinInterval(filetype, start, stop, bIncStart=false, bIncEnd=false)
      arrFiles    = Array.new
      arrResult   = Array.new

      # Patch @ Casale Beach

      if start != nil and start != "" and stop != nil and stop != "" then
         arrFiles = ArchivedFile.find :all, :conditions => {:validity_start => (start..stop)}
      else
         # if no filetype is specified, retrieve everything
         if filetype != nil and filetype != "" then
            # ----------------------------------------------
            # Rails 3 
            # arrFiles = ArchivedFile.find_all_by_filetype(filetype)
            # ----------------------------------------------
            # Rails 4 
            arrFiles = ArchivedFile.where(filetype: filetype).load
            # ----------------------------------------------
         else
            arrFiles = ArchivedFile.find(:all)
         end
      end

      # puts "#{arrFiles.length} records found"

      # if start and stop criteria are defined, filter files
      if start != nil and stop != nil and start != "" and stop != "" then

         arrFiles.each{|aFile|
           
            # if the file is missing a valid validity interval, discard it
            if aFile.validity_start == nil or aFile.validity_stop == nil then
               next
            end

            # patch because accessors return a Time object instead of DateTime
            tmp = aFile.validity_start
            file_start = DateTime.new(tmp.strftime("%Y").to_i, tmp.strftime("%m").to_i, tmp.strftime("%d").to_i, tmp.strftime("%H").to_i, tmp.strftime("%M").to_i, tmp.strftime("%S").to_i)
            tmp = aFile.validity_stop
            file_stop  = DateTime.new(tmp.strftime("%Y").to_i, tmp.strftime("%m").to_i, tmp.strftime("%d").to_i, tmp.strftime("%H").to_i, tmp.strftime("%M").to_i, tmp.strftime("%S").to_i)

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

      return fixDateFormat(arrResult)

   end
   #-------------------------------------------------------------

   def ArchivedFile.searchAllByName(pattern)
      arrFiles    = Array.new
      sqlPattern  = convertWildCards(pattern)

      if ENV['MINARC_DB_ADAPTER'] == "oracle" then
         arrFiles = ArchivedFile.find_by_sql("SELECT * FROM archived_files WHERE filename LIKE '#{sqlPattern}' ESCAPE '\\'")
      else
         arrFiles = ArchivedFile.find_by_sql("SELECT * FROM archived_files WHERE filename LIKE '#{sqlPattern}'")
      end

      return fixDateFormat(arrFiles)

   end

   #-------------------------------------------------------------


   def ArchivedFile.getNewFiles(aDate)
      arrFiles    = Array.new
      arrResult   = Array.new

      arrFiles = ArchivedFile.all

      arrFiles.each{|aFile|
        
        
            
        if aFile.archive_date == nil then
           puts "#{aFile.filename} does not have archive date !"
           next
        end
            
        tmp            = aFile.archive_date
        archive_date   = DateTime.new(tmp.strftime("%Y").to_i, tmp.strftime("%m").to_i, tmp.strftime("%d").to_i, tmp.strftime("%H").to_i, tmp.strftime("%M").to_i, tmp.strftime("%S").to_i)
             
        if (aDate < archive_date) then
           # puts aFile.archive_date
           arrResult << aFile  
        end
         
      }
      
      return fixDateFormat(arrResult)
      
   end
   #-------------------------------------------------------------

   def ArchivedFile.getFileTypes()
      return ArchivedFile.find_by_sql("SELECT distinct filetype FROM archived_files")
   end
   #-------------------------------------------------------------

   def ArchivedFile.deleteAll(condition = "")
      puts ArchivedFile.delete_all(condition)
      if condition == "" then
         puts "\nMINARC::ArchivedFile.deleteAll missing condition ! :-( \n\n"
         return false
      end
   end
   #-------------------------------------------------------------

private

   def ArchivedFile.convertWildCards(filename)
      
      # change '*' in '%'
      filename = filename.tr('\*', '%')

      # change all '_' by '\_' in two steps
      filename =  filename.tr('_', '|')
      tmp =  filename.sub!('|', '\_')
      while (tmp != nil)
         filename = tmp
         tmp = tmp.sub!('|', '\_')
      end

      # change all '?' in '_'
      filename = filename.tr('?', '_')

      return filename
   end
   #-------------------------------------------------------------

   def ArchivedFile.fixDateFormat(arrFiles)

      arrFiles.each{|aFile|

         if aFile.validity_start.is_a?(Time) then
            aFile.validity_start = DateTime.parse(aFile.validity_start.strftime("%Y%m%dT%H%M%S"))
         end

         if aFile.validity_stop.is_a?(Time) then
            aFile.validity_stop = DateTime.parse(aFile.validity_stop.strftime("%Y%m%dT%H%M%S"))
         end
      }

      return arrFiles
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------

end


#=====================================================================


#-----------------------------------------------------------


