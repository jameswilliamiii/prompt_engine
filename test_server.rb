#!/usr/bin/env ruby
# Quick test to verify the engine is working

require 'net/http'
require 'uri'

puts "Starting test server..."
pid = spawn("cd spec/dummy && rails s -p 3001", out: "/dev/null", err: "server_errors.log")

puts "Waiting for server to start..."
sleep 5

begin
  uri = URI.parse("http://localhost:3001/active_prompt")
  response = Net::HTTP.get_response(uri)
  
  puts "Response code: #{response.code}"
  puts "Response body preview: #{response.body[0..200]}..." if response.body
  
  if File.exist?("server_errors.log")
    puts "\nServer errors:"
    puts File.read("server_errors.log")
  end
ensure
  puts "\nStopping server..."
  Process.kill("TERM", pid)
  Process.wait(pid)
  File.delete("server_errors.log") if File.exist?("server_errors.log")
end