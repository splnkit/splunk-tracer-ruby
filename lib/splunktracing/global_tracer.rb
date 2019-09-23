require 'singleton'

module SplunkTracing
  # GlobalTracer is a singleton version of the SplunkTracing::Tracer.
  #
  # You should access it via `SplunkTracing.instance`.
  class GlobalTracer < Tracer
    private
    def initialize
    end

    public
    include Singleton

    # Configure the GlobalTracer
    # See {SplunkTracing::Tracer#initialize}
    def configure(**options)
      if configured
        SplunkTracing.logger.warn "[SplunkTracing] Already configured"
        SplunkTracing.logger.info "Stack trace:\n\t#{caller.join("\n\t")}"
        return
      end

      self.configured = true
      super
    end

    private

    attr_accessor :configured
  end
end
