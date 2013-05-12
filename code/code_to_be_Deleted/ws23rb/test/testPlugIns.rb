#!/usr/bin/env ruby

require "ws23rb/WS_PlugIn_Loader"
require "ws23rb/WS_PlugIn_dewpoint"


plugIn = WS23RB::WS_PlugIn_Loader.new("dewpoint", true)

if plugIn.isPlugInLoaded? == false then
   exit
end

puts plugIn.variable

puts plugIn.unit

puts plugIn.thresholds

puts plugIn.verifyThresholds(80.9)

puts plugIn.failedThreshold
