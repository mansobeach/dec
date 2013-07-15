require 'cuc/Converters'

include CUC::Converters

strDate = "20120325T154814"

aDate = self.str2date(strDate)

puts aDate
