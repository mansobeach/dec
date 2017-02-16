require 'cuc/Converters'

include CUC::Converters


strDate = "21-MAY-2015 14:00:01.516"

puts strDate.length
puts strDate.slice(2,1)
puts strDate.slice(6,1)


aDate = self.str2date(strDate)

puts aDate


exit

strDate = "20120325T154814"

aDate = self.str2date(strDate)

puts aDate



