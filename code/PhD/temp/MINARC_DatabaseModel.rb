#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MINARC_DatabaseModel class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: MINARC_DatabaseModel.rb,v 1.14 2009/03/18 12:25:01 decdev Exp $
#
# module MINARC
#
#########################################################################

require "rubygems"
require "active_record"

dbAdapter   = ENV['MINARC_DB_ADAPTER']
dbName      = ENV['MINARC_DATABASE_NAME']
dbUser      = ENV['MINARC_DATABASE_USER']
dbPass      = ENV['MINARC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(:adapter => dbAdapter,
         :host => "localhost", :database => dbName,
         :username => dbUser, :password => dbPass)

class ArchivedFile < ActiveRecord::Base
   validates_presence_of   :filename
   validates_uniqueness_of :filename
   validates_presence_of   :filetype
   validates_presence_of   :archive_date
   validates_presence_of   :filesize


   #--------------------------------------------------------

   def ArchivedFile.searchAllWithinInterval(filetype, start, stop, bIncStart=false, bIncEnd=false)
      arrFiles    = Array.new
      arrResult   = Array.new

      # if no filetype is specified, retrieve everything
      if filetype != nil and filetype != "" then
         arrFiles = ArchivedFile.find_all_by_filetype(filetype)
      else
         arrFiles = ArchivedFile.find(:all)
      end

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
   #----------------------------------------------------------------------------

   def ArchivedFile.searchAllByName(pattern)
      arrFiles    = Array.new
      sqlPattern  = convertWildCards(pattern)

      if ENV['MINARC_DB_ADAPTER'] == "oracle" then
         arrFiles = ArchivedFile.find_by_sql("SELECT * FROM archived_files WHERE filename LIKE '#{sqlPattern}' ESCAPE '\\'")
      else
         arrFiles = ArchivedFile.find_by_sql("SELECT * FROM archived_files WHERE filename LIKE '#{sqlPattern}'")
      end

      return c(arrFiles)

   end

   #----------------------------------------------------------------------------
   
   # This method aims to patch Y2K38 BUG
   def ArchivedFile.fixDate(aFile)

      if aFile == nil then
         return nil
      end

      if aFile.validity_start.is_a?(Time) then
         aFile.validity_start = DateTime.parse(aFile.validity_start.strftime("%Y%m%dT%H%M%S"))
      end

      if aFile.validity_stop.is_a?(Time) then
         aFile.validity_stop = DateTime.parse(aFile.validity_stop.strftime("%Y%m%dT%H%M%S"))
      end

      return aFile
   end
   #-------------------------------------------------------------

   #--------------------------------------------------------

   def ArchivedFile.getFileTypes()
      return ArchivedFile.find_by_sql("SELECT distinct filetype FROM archived_files")
   end
   #--------------------------------------------------------

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

end


#=====================================================================


#-----------------------------------------------------------


