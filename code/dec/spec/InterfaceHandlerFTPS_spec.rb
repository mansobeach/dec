#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #InterfaceHandlerFTPS class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Collector Component
# 
# Git: $Id: InterfaceHandlerAbstract.rb,v 1.12 2014/05/16 00:14:38 bolf Exp $
#
# Module Interface
# This is an abstract class that defines the interface handler methods
#
#########################################################################

require 'rspec'
require 'DEC_Environment'
require 'InterfaceHandlerFTPS'

RSpec.describe 'InterfaceHandlerAbstract method implementation compliance' do
   before { DEC_Environment.new.load_config}

   before { @handler = DEC::InterfaceHandlerFTPS.new("NOAA", nil, true, false) }
      
   it 'implements setDebugMode' do
      expect(@handler).to respond_to(:setDebugMode).with(0).argument
   end

   it 'can be inspected' do
      expect(@handler).to respond_to(:inspect).with(0).argument
   end

   it 'implements check the interface'

   it 'implements pushFile' do
      expect(@handler).to respond_to(:pushFile).with(3).arguments
   end
   
   it 'implements getUploadDirList' do
      expect(@handler).to respond_to(:getUploadDirList).with(1).argument
   end
   
   it 'implements getList' do
      expect(@handler).to respond_to(:getList).with(0).argument
   end   
   
end
