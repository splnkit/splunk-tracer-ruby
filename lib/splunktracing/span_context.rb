module SplunkTracing
  # SpanContext holds the data for a span that gets inherited to child spans
  class SpanContext
    attr_reader :id, :trace_id, :parent_id, :baggage

    def initialize(id:, trace_id:, parent_id: nil, baggage: {})
      @id = id.freeze
      @trace_id = trace_id.freeze
      @parent_id = parent_id.freeze
      @baggage = baggage.freeze
    end
  end
end
