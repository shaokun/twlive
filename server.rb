require 'rubygems'
require 'em-websocket'
require 'em-http'
require 'json'

USERNAME = 'YOURUSERNAME'
PASSWORD = 'YOURPASSWORD'

sample_url = 'http://stream.twitter.com/1/statuses/sample.json'
filter_url = 'http://stream.twitter.com/1/statuses/filter.json?track=iphone'


EM.run do
  channel = EM::Channel.new
  http = EventMachine::HttpRequest.new(filter_url).get :head => { 'Authorization' => [ USERNAME, PASSWORD ] }

  buffer = ""

  http.stream do |chunk|
    buffer += chunk
    while line = buffer.slice!(/.+\r?\n/)
      tweet = JSON.parse(line)
      next unless tweet['text']
      
      msg = "<span style='font-weight: bold; color: blue'>#{tweet['user']['screen_name']}</span>:&nbsp;&nbsp;&nbsp;&nbsp;#{tweet['text']}"
      
      puts "\t#{msg}"
      channel << msg
    end
  end
  
  EventMachine::WebSocket.start(:host => "localhost", :port => 8080) do |ws|
    ws.onopen do
      puts "WebSocket opened"
      
      @sid = channel.subscribe do |msg|
        ws.send msg
      end
    end
    
    ws.onclose do
      channel.unsubscribe @sid
      
      puts "WebSocket closed"
    end
  end
end