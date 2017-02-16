#!/usr/bin/env ruby

require 'rubygems'
require 'mini_exiftool'


# Writing meta data
photo = MiniExiftool.new '20101224T221412_000041.m2ts'

photo.title = 'This is the new title'

# photo.date_time_original = Time.now

ret = photo.save

puts ret
