#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #createORCTables.rb module
#
# === Written by DEIMOS Space S.L. (rell)
#
# === MDS-LEGOS -> ORC Component
# 
# CVS: $Id: createORCTables.rb,v 1.9 2009/03/18 11:14:42 decdev Exp $
#
# module ORC
#
#########################################################################



require 'ORC_DataModel'
require 'ORC_Migrations'

puts "START"

if TriggerProduct.table_exists?() == false then
   CreateTriggerProducts.up
end

if Pending2QueueFile.table_exists?() == false then
   CreatePending2QueueFiles.up
end

if ProductionTimeline.table_exists?() == false then
   CreateProductionTimelines.up
end


if SuccessfulTriggerProduct.table_exists?() == false then
   CreateSuccessfulTriggerProducts.up
end

if FailingTriggerProduct.table_exists?() == false then
   CreateFailingTriggerProducts.up
end

if DiscardedTriggerProduct.table_exists?() == false then
   CreateDiscardedTriggerProducts.up
end

if OrchestratorQueue.table_exists?() == false then
   CreateOrchestratorQueue.up
end

if ObsoleteTriggerProduct.table_exists?() == false then
   CreateObsoleteTriggerProducts.up
end

if OrchestratorMessage.table_exists?() == false then
   CreateOrchestratorMessages.up
end

if MessageParameter.table_exists?() == false then
   CreateMessageParameters.up
end 

if RunningJob.table_exists?() == false then
   CreateRunningJobs.up
end

puts "END"
