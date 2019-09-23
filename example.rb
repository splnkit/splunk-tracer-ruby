require 'bundler/setup'
require 'simplecov'
SimpleCov.command_name 'example.rb'
SimpleCov.start
require 'splunktracing'

access_token = '{your_access_token}'

SplunkTracing.configure(component_name: 'splunktracing/ruby/example', access_token: access_token)

puts 'Starting operation...'
span = SplunkTracing.start_span('my_span')
thread1 = Thread.new do
  (1..10).each do |i|
    sleep(0.15)
    puts "Logging event #{i}..."
    span.log(event: 'hello world', count: i)
  end
end
thread2 = Thread.new do
  current = 1
  (1..16).each do |i|
    child = SplunkTracing.start_span('my_child', child_of: span.span_context)
    sleep(0.1)
    current *= 2
    child.log(event: "2^#{i}", result: current)
    child.finish
  end
end
[thread1, thread2].each(&:join)
span.finish
SplunkTracing.flush
puts 'Done!'
puts "https://app.splunktracing.com/#{access_token}/trace?span_guid=#{span.span_context.id}&at_micros=#{span.start_micros}"
