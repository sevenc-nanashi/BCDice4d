# frozen_string_literal: true

require "discorb"
require "dotenv/load"

client = Discorb::Client.new

client.once :standby do
  puts "Logged in as #{client.user}"
end

client.run ENV["TOKEN"]
