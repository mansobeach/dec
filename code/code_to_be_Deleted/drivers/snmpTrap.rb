#!/usr/bin/ruby

  require 'snmp'
  require 'logger'

  log = Logger.new(STDOUT)
  m = SNMP::TrapListener.new do |manager|
      manager.on_trap_default do |trap|
          log.info trap.inspect
      end
  end
  m.join
