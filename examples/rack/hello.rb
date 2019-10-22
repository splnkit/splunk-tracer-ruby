require 'bundler/setup'
require 'splunktracing'

require 'rack'
require 'rack/server'

SplunkTracing.configure(
  component_name: 'splunktracing/ruby/examples/rack',
  access_token: '{your_access_token}'
)

class HelloWorldApp
  def self.call(env)
    span = SplunkTracing.start_span('request',tags: {name: "G"})
    span.log event: 'env', env: env
    resp = [200, {}, ["Hello World. You said: #{env['QUERY_STRING']}"]]
    span.finish
    resp
  end
end

Rack::Server.start app: HelloWorldApp
