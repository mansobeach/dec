#!/usr/bin/env ruby

require 'ORC_DataModel'
require 'ORC_Migrations'

puts "START"

if ProductionTimeline.table_exists?() then
   CreateProductionTimelines.down
end

if ObsoleteTriggerProduct.table_exists?() then
   CreateObsoleteTriggerProducts.down
end

if SuccessfulTriggerProduct.table_exists?() then
   CreateSuccessfulTriggerProducts.down
end

if FailingTriggerProduct.table_exists?() then
   CreateFailingTriggerProducts.down
end

if OrchestratorQueue.table_exists?() then
   CreateOrchestratorQueue.down
end

if TriggerProduct.table_exists?() then
   CreateTriggerProducts.down
end

if MessageParameter.table_exists?() then
   CreateMessageParameters.down
end 

if OrchestratorMessage.table_exists?() then
   CreateOrchestratorMessages.down
end

if RunningJob.table_exists?() then
   CreateRunningJobs.down
end

puts "END"
