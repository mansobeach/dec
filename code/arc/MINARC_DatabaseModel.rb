#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'active_record'
require 'activerecord-import'
require 'bcrypt'

require 'arc/ReadMinarcConfig'

dbAdapter   = ENV['MINARC_DB_ADAPTER']
dbHost      = ENV['MINARC_DATABASE_HOST']
dbPort      = ENV['MINARC_DATABASE_PORT']
dbName      = ENV['MINARC_DATABASE_NAME']
dbUser      = ENV['MINARC_DATABASE_USER']
dbPass      = ENV['MINARC_DATABASE_PASSWORD']

ActiveRecord::Base.establish_connection(
                                          :adapter    => dbAdapter,
                                          :host       => dbHost, 
                                          :database   => dbName,
                                          :port       => dbPort,
                                          :username   => dbUser, 
                                          :password   => dbPass, 
                                          :timeout    => 100000,
                                          :cast       => false,
                                          :pool       => 10
                                          )


## =====================================================================

class User < ActiveRecord::Base
   include BCrypt
   has_secure_password
   validates_uniqueness_of :name
   validates :name, presence: true, uniqueness: { case_sensitive: false }
   # has_secure_password :password, validations: false
   
  def validate
    super
    validates_unique(:name)
    validates_presence([:name])
    validates_format(USERNAME_REGEXP, :name)
  end   
end

## =====================================================================

class ServedFile < ActiveRecord::Base
   
  def validate
    super
    validates_presence([:filename])
    validates_presence([:username])
    validates_presence([:download_date])
  end   
end

## =====================================================================

class ArchivedFile < ActiveRecord::Base

   self.implicit_order_column = "id"

   validates_presence_of   :name
   validates_uniqueness_of :name

   validates_presence_of   :filename
   validates_uniqueness_of :filename

   validates_presence_of   :filetype
   validates_presence_of   :archive_date

   # --------------------------------------------------------
   
   def json_introspection
      return hash_introspection.to_json
      # return JSON.pretty_generate(hash_introspection.to_json)
   end
   # --------------------------------------------------------
   
   def hash_introspection
   
      # require 'arc/ReadMinarcConfig'
      config   = ARC::ReadMinarcConfig.instance
      server   = config.getArchiveServer
      hFile    = Hash.new

      hFile['uuid']              = self.uuid      
      hFile['name']              = self.name
      hFile['filename']          = self.filename
      hFile['filename_original'] = self.filename_original
      hFile['url']               = "#{server}/odata/v1/Products(#{self.uuid})/$value"
      hFile['path']              = self.path
      hFile['filetype']          = self.filetype
      hFile['validity_start']    = self.validity_start
      hFile['validity_stop']     = self.validity_stop
      hFile['size']              = self.size
      hFile['size_original']     = self.size_original
      hFile['size_in_disk']      = self.size_in_disk
      hFile['archive_date']      = self.archive_date
      hFile['last_access_date']  = self.last_access_date
      hFile['access_counter']    = self.access_counter
      hFile['info']              = self.info      
      hFile['md5']               = self.md5

      begin
         hFile['json_metadata']  = self.json_metadata
      rescue Exception => e
         puts "BADURA"
         puts e.to_s
      end

      return hFile
   end
   # --------------------------------------------------------
   
   def print_introspection
   
      config   = ARC::ReadMinarcConfig.instance
      server   = config.getArchiveServer
   
      puts "uuid            : #{self.uuid}"
      puts "Logical name    : #{self.name}"
      puts "Physical name   : #{self.filename}"
      puts "Original name   : #{self.filename_original}"
      puts "URL             : #{server}/odata/v1/Products(#{self.uuid})/$value"
      puts "Path            : #{self.path}"
      puts "Filetype        : #{self.filetype}"
      puts "Size            : #{self.size} Bytes"
      puts "Size Original   : #{self.size_original} Bytes"
      puts "Disk Occupation : #{self.size_in_disk} Bytes"
      puts "md5             : #{self.md5}"
      puts "Archive Date    : #{self.archive_date}"
      puts "Last Access     : #{self.last_access_date}"
      puts "Info            : #{self.info}"
      puts "Num Access      : #{self.access_counter}"
      begin
         puts "json_metadata   : #{self.json_metadata}"
      rescue Exception => e
         puts "missing json_metadata"
         put e.to_s
      end
   end
   # --------------------------------------------------------

   def ArchivedFile.superBulkSequel_mysql2(hashRecords)
      
      require 'sequel'
      
      db = Sequel.connect( 
                           :adapter    => "#{ENV['MINARC_DB_ADAPTER']}",
                           #:adapter    => "sqlite",
                           :user       => "#{ENV['MINARC_DATABASE_USER']}", 
                           :host       => "localhost", 
                           :database   => "#{ENV['MINARC_DATABASE_NAME']}"
                           )
      
      ret = db[:archived_files].multi_insert(hashRecords)
   end
   #--------------------------------------------------------

   def ArchivedFile.superBulk(files, columns)
      ret = ArchivedFile.import columns, files, :batch_size => 999, :validate => false
      puts ret
   end
   #--------------------------------------------------------

   def ArchivedFile.bulkImport(arrFiles, columns)
      ret = ArchivedFile.import columns, arrFiles, :validate => false     
      puts ret
      exit
   end
   #--------------------------------------------------------

   def ArchivedFile.searchAllWithinInterval(filetype, start, stop, bIncStart=false, bIncEnd=false)
      arrFiles    = Array.new
      arrResult   = Array.new

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

end

## ===================================================================
