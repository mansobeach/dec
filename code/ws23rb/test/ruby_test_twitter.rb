require "rubygems"
require "serialport"
require "oauth"
require "twitter"
require "spreadsheet"



bDebugMode  = true

portname    = ARGV[0]
baudrate    = 9600
data_bits   = 8
stop_bits   = 1
parity      = SerialPort::NONE

arduino = SerialPort.new(portname, baudrate, data_bits, stop_bits, parity)

sleep 2

prevMessage = ""
strMessage  = ""
bAlarm      = false
prevbAlarm  = false

valLWR      = 0
valTherm    = 0

# --------------------------------------------------------------------

Twitter.configure do |config|
   config.consumer_key         = "hBDuZ4qAKuARsvUZcbrlFA"
   config.consumer_secret      = "WyMV55meL1WUP04yCjycYzcZcdZAZFYCHAqcpbWv1nI"
   config.oauth_token          = "407966574-pRNuvKUB5J3KigcHS3VTFi0wcoqEMikBWYDTjGPs"
   config.oauth_token_secret   = "FfsmFMJRtHpoVqYmalwFKJZxyx0XMRdGps8XhRUAU"
end

clientTwitter = Twitter::Client.new

# --------------------------------------------------------------------

workbook    = Spreadsheet::Workbook.new()
worksheet   = workbook.create_worksheet()

worksheet[0, 0] = "Date"
worksheet[0, 1] = "LWR"
worksheet[0, 2] = "Thermistor"

workbook.write("test.xls")

sheetRow       = 1

sheetColDate   = 0
sheetColLWR    = 1
sheetColTherm  = 2

# --------------------------------------------------------------------




# --------------------------------------------------------------------

while true
   now      = Time.now
   strNow   = now.strftime("%H:%M:%S")

   prevMessage = strMessage
   
   strTmp      = arduino.gets.chomp
   if strTmp == "" then
      next
   end
   strMessage  = strTmp
   
   if bDebugMode == true then 
      puts strMessage
   end

   if strMessage.include?("Resistor") == true then
      valLWR = strMessage.split("Value:")[1]
      worksheet[sheetRow, sheetColDate]   = now
      worksheet[sheetRow, sheetColLWR]    = valLWR.to_i
      puts valLWR
   end

   if strMessage.include?("Thermistor") == true then
      valTherm = strMessage.split("Value:")[1]
      worksheet[sheetRow, sheetColTherm]    = valTherm.to_i
      workbook.write("test.xls")
      sheetRow = sheetRow + 1
      puts valTherm.to_i
   end


   # Alarm has been disabled
   if prevbAlarm == true and bAlarm == false then
      if bDebugMode == true then
         puts "ALARM IS FINISHED"
      end
      twitterMsg = "#{strNow} - It is a new Dawn in the Casale"
      clientTwitter.update(twitterMsg)
      puts twitterMsg
   end

   prevbAlarm  = bAlarm

   if prevMessage.include?("Thermistor") == true and strMessage.include?("Resistor") == true then
      if bDebugMode == true then
         puts "NO ALARM IS RAISED"
      end
      bAlarm = false
      next
   end

   if strMessage.include?("ALARM") and (bAlarm == false) then
      puts "ALARM CASALE"
      bAlarm = true           

      if strMessage.include?("ALARM-01") then
         twitterMsg = "#{strNow} - It is Dusk in the Casale"
         clientTwitter.update(twitterMsg)
         puts twitterMsg
      end

      if strMessage.include?("ALARM-02") then
         now = Time.now
         strNow = now.strftime("%H:%M:%S")
         twitterMsg = "#{strNow} - It is cold ! :-/"
         clientTwitter.update(twitterMsg)
         puts twitterMsg
      end
   end

end
