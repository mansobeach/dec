#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EOLIDataProcessor class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# ==== Data Exchange Component -> EOLI Client Component
# 
# CVS:
#
# = This module processes the response data retrieved by the queries 
# = performed by an #EOLIClient.
# == This class works with the data structures (Hash objects) created 
# == in the #EOLIClient class in the private methods fillXXXXXStruct.
#
#########################################################################


module EOLIDataProcessor

   #-------------------------------------------------------------
   
   # It shows selected Fields via the standard output 
   def showSelectedFields(arrHashData, arrFields, showHeaders = true)
      if arrHashData.length <= 0 then
         STDERR.puts "Error in EOLIDataProcessor::showSelectedFields"
	 exit(99)
      end
      
      # Check that all fields are present in the data structure
      arrFields.each{|field|
         if arrHashData[0].has_key?(field.upcase) == false then
	    STDERR.puts "Error in EOLIDataProcessor::showSelectedFields"
	    STDERR.puts "#{field} field is not present in the data structure !"
	    STDERR.puts
	    exit(99)
	 end
      }
      
      # If show Headers
      if showHeaders == true then
         arrFields.each{|field|
            print "#{field}-"
	    lFieldName = field.length
	    lValue     = arrHashData[0][field].length
	    diff       = lValue - lFieldName
	    if diff > 0 then
	       1.upto(diff) do |x|
	          print "-"
	       end
	    end
         }
	 STDERR.puts
      end
      
      @numRows = 0
      # By GROUPS?
      arrHashData.each{|row|
         arrFields.each{|field|
	    print "#{row[field]} "
            lFieldName = field.length
	    lValue     = row[field].length
	    diff       = lFieldName - lValue
	    if diff > 0 then
	       1.upto(diff) do |x|
	          print " "
	       end
	    end
	 }
	 @numRows = @numRows + 1
         STDERR.puts
      }
      
   end
   #-------------------------------------------------------------

   def getAllValuesOfField(arrHashData, fieldName)
      if arrHashData.length <= 0 then
         STDERR.puts "Error in EOLIDataProcessor::getValuesOfField"
	 exit(99)
      end
      
      # Check that all fields are present in the data structure
      if arrHashData[0].has_key?(fieldName) == false then
         STDERR.puts "Error in EOLIDataProcessor::getValuesOfField"
	 STDERR.puts "#{field} field is not present in the data structure !"
	 STDERR.puts
	 exit(99)
      end
      
      arrResult = Array.new
      
      arrHashData.each{|row|
         arrResult << row[fieldName]
      }
      return arrResult
   end
   #-------------------------------------------------------------
   
   def showMQuerySelectedFields(arrHashData, arrFields)
#       if arrHashData.length <= 0 then
#          STDERR.puts "Error in EOLIDataProcessor::showMultipleQuerySelectedFields"
# 	      STDERR.puts arrHashData.class
#          STDERR.puts arrHashData.length
#          STDERR.puts arrHashData
#          exit(99)
#       end
      @numRows      = 0
      @numTotalRows = 0
      bFirstTime    = true
      arrHashData.each{|queryResult|
         showSelectedFields(queryResult, arrFields, bFirstTime)
	      if bFirstTime == true then
	         bFirstTime = false
	      end
	      @numTotalRows = @numTotalRows + @numRows
      }
      STDERR.puts
      STDERR.puts "#{@numTotalRows} Elements showed"
      STDERR.puts
   end 
   #-------------------------------------------------------------

   def showMQueryMGroupsSelectedFields(arrHashData, arrFields)
      if arrHashData.length <= 0 then
         STDERR.puts "Error in EOLIDataProcessor::showMultipleQuerySelectedFields"
	      exit(99)
      end
      @numRows      = 0
      @numTotalRows = 0
      bFirstTime = true
      arrHashData.each{|queryResult|
         queryResult.each{|group|
            showSelectedFields(group, arrFields, bFirstTime)
	    if bFirstTime == true then
	       bFirstTime = false
	    end
	    @numTotalRows = @numTotalRows + @numRows
	 }
      }
      STDERR.puts
      STDERR.puts "#{@numTotalRows} Elements showed"
      STDERR.puts
   end 
   #-------------------------------------------------------------
   
   def getRowSelectedFields(row, hashFields)
      hashFields.each{|field|
         hashFields[field] = row[field]
      }
   end
   #-------------------------------------------------------------
  
end
