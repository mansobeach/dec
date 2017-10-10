#!/usr/bin/ruby

require 'sequel'

db = Sequel.connect(:adapter => 'mysql2', :user => "#{ENV['MINARC_DATABASE_USER']}", :host => "localhost", :database => "#{ENV['MINARC_DATABASE_NAME']}")

ret = db[:archived_files].multi_insert( [ 
					{ :filename => 'TEST_KAKA_1', :filetype => 'KAKA', :path => '/home/kaka', :size => 0 },
					{ :filename => 'TEST_KAKA_2', :filetype => 'KAKA', :path => '/home/kaka', :size => 0 },
					{ :filename => 'TEST_KAKA_3', :filetype => 'KAKA', :path => '/home/kaka', :size => 0 }
                                  ] )

puts ret


