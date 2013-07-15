#!/usr/bin/env ruby

require 'cuc/Log4rLoggerFactory'  

pwd = ENV['PWD']

# Auto-config from file 
loggerFactory = CUC::Log4rLoggerFactory.new("SenderClassName:method", "#{ENV['PWD']}/test_log_conf.xml")

loggerFactory.setDebugMode


# #Manual setup
# loggerFactory = CUC::Log4rLoggerFactory.new()
# 
# loggerFactory.setup("roudoudou", "/tmp/nrt_processor.log", false, true)
# 
# loggerFactory.setDebugMode

# test
logger = loggerFactory.getLogger

logger.debug("This is a DEBUG message")
logger.info("This is a INFO message")
logger.warn("This is a WARNING message")
logger.error("This is a ERROR message")
logger.fatal("This is a FATAL message")
