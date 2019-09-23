require 'splunktracing/transport/base'

module SplunkTracing
  module Transport
    class Callback < Base
      def initialize(callback:)
        @callback = callback
      end

      def report(report)
        @callback.call(report)
        nil
      end
    end
  end
end
