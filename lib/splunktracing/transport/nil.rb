require 'splunktracing/transport/base'

module SplunkTracing
  module Transport
    # Empty transport, primarily for unit testing purposes
    class Nil < Base
    end
  end
end
