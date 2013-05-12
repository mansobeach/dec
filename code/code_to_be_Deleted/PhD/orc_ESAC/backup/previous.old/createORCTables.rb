#!/usr/bin/env ruby

require 'ORC_DataModel'
require 'ORC_Migrations'

puts "START"

CreateTriggerProducts.up

CreateOrchestratorQueue.up

CreateFailingTriggerProducts.up

CreateSuccessfulTriggerProducts.up

CreateObsoleteTriggerProducts.up

CreateProductionTimelines.up

CreateOrchestratorMessages.up

CreateMessageParameters.up

CreateRunningJobs.up

puts "END"
