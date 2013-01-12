#!/usr/bin/ruby
require "serialport"
require "httparty"
require "json"

def main
  #params for serial port
  device = ""
  baudRate = 115200
  dataBits = 8
  stopBits = 1
  parity = SerialPort::NONE

  hashtag = ""
  displayText = ""
  response = ""

  # Check for command line arguments
  if ARGV.length < 2
    puts "Usage: ./twitter2serial.rb DEVICE SEARCHTERM"
    exit
  end
  device = ARGV[0]
  hashtag = ARGV[1]

  # Try to open connection to serial port
  begin
    sp = SerialPort.new(device, baudRate, dataBits, stopBits, parity)
  rescue
    puts "No such serial device."
    exit
  end

  # Wait for "CTRL c" and close the serial port, resetting the Arduino 
  trap "INT" do
    puts "Shutting down." 
    sp.dtr= 0
    sp.close 
    exit
  end

  # Read for ever from serial port
  while true do
    response += sp.getc.chomp
    if response =~ /READY/
      response = ""
      displayText = getTweet hashtag
      puts "#{displayText}\n"
      sp.puts "#{displayText}\n"
    end
  end
end

# Get the most recent tweet for a specific searchterm
def getTweet searchterm
  response = nil
  while response == nil
  response = HTTParty.get("https://search.twitter.com/search.json", 
    :query => { :q => searchterm, :rpp => 1, :result_type => "recent"})
  end

  json = JSON.parse(response.body)
  if json["results"].length > 0
    text = json["results"][0]["text"]
  else
	 text = "No match for '#{hashtag}'"
  end
  text = text.gsub(/\n/," ") #remove newlines
  text.gsub(/ ( )+/," ")     #remove multiple spaces
end

main