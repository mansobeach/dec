#!/usr/bin/env ruby


arrData = ["0C08", "FFFF", "0E44", "0001", "CEEE", "3F55", "2C03"]


# ----------------------------------------

# Commutative property for a pair of operators the XOR

result = "FFFF".hex ^ "FFFF".hex 
puts result.to_s(16)

result = "0000".hex ^ "FFFF".hex 
puts result.to_s(16)

result = "FFFF".hex ^ "0000".hex 
puts result.to_s(16)

result = "0000".hex ^ "0000".hex 
puts result.to_s(16)

# ----------------------------------------

# Final XOR 0005 at the end of the sequence of words

cksum_nuc = "0000"

arrData.each{|element|
   cksum_nuc = (cksum_nuc.hex ^ element.hex).to_s(16)
}

cksum_nuc = (cksum_nuc.hex ^ "0005".hex).to_s(16)

puts cksum_nuc

# ----------------------------------------

# Final XOR 0005 at the end of the sequence of words

cksum_nuc = (arrData[0].hex ^ arrData[1].hex).to_s(16)

2.upto(arrData.length - 1) do |index|
    cksum_nuc = (cksum_nuc.hex ^ arrData[index].hex).to_s(16)
end

cksum_nuc = (cksum_nuc.hex ^ "0005".hex).to_s(16)

puts cksum_nuc

# ----------------------------------------

# ----------------------------------------

# XOR 0005 at the beginning of the sequence of words

cksum_nuc = "0005"

arrData.each{|element|
   cksum_nuc = (cksum_nuc.hex ^ element.hex).to_s(16)
}


puts cksum_nuc
