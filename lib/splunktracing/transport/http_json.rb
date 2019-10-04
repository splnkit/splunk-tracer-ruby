require 'net/http'
require 'openssl'
require 'zlib'
require 'splunktracing/transport/base'

module SplunkTracing
  module Transport
    # HTTPJSON is a transport that sends reports via HTTP in JSON format.
    # It is thread-safe.
    class HTTPJSON < Base
      SPLUNK_HEC_HOST = 'localhost'.freeze
      SPLUNK_HEC_PORT = 8088

      ENCRYPTION_TLS = 'tls'.freeze
      ENCRYPTION_NONE = 'none'.freeze

      REPORTS_API_ENDPOINT = '/services/collector'.freeze
      HEADER_ACCESS_TOKEN = 'Authorization'.freeze

      ##
      # Initialize the transport
      #
      # @param host [String] host of the domain to the endpoint to push data
      # @param port [Numeric] port on which to connect
      # @param verbose [Numeric] verbosity level. Right now 0-3 are supported
      # @param encryption [ENCRYPTION_TLS, ENCRYPTION_NONE] kind of encryption to use
      # @param access_token [String] access token for SplunkTracing server
      # @param ssl_verify_peer [Boolean]
      # @param open_timeout [Integer]
      # @param read_timeout [Integer]
      # @param continue_timeout [Integer]
      # @param keep_alive_timeout [Integer]
      # @param logger [Logger]
      #
      def initialize(
        host: SPLUNK_HEC_HOST,
        port: SPLUNK_HEC_PORT,
        verbose: 0,
        encryption: ENCRYPTION_TLS,
        access_token:,
        ssl_verify_peer: false,
        open_timeout: 20,
        read_timeout: 20,
        continue_timeout: nil,
        keep_alive_timeout: 2,
        logger: nil
      )
        @host = host
        @port = port
        @verbose = verbose
        @encryption = encryption
        @ssl_verify_peer = ssl_verify_peer
        @open_timeout = open_timeout.to_i
        @read_timeout = read_timeout.to_i
        @continue_timeout = continue_timeout
        @keep_alive_timeout = keep_alive_timeout.to_i

        raise Tracer::ConfigurationError, 'access_token must be a string' unless access_token.is_a?(String)
        raise Tracer::ConfigurationError, 'access_token cannot be blank'  if access_token.empty?
        @access_token = access_token
        @logger = logger || SplunkTracing.logger
      end

      ##
      # Queue a report for sending
      #
      def report(report)
        @logger.info report if @verbose >= 3

        req = build_request(report)
        res = connection.request(req)

        @logger.info res.to_s if @verbose >= 3

        nil
      end

      private

      ##
      # @param [String] report_string
      # @return [Net::HTTP::Post]
      #
      def build_request(report)
        gzip = Zlib::GzipWriter.new(StringIO.new)
        gzip << convert_report_data(report)
        req = Net::HTTP::Post.new(REPORTS_API_ENDPOINT)
        req[HEADER_ACCESS_TOKEN] = 'Splunk ' + @access_token
        req['Content-Type'] = 'application/json'
        req['Content-Encoding'] = 'gzip'
        req['Connection'] = 'keep-alive'
        req.body = gzip.close.string
        req
      end

      ##
      # @param [Hash] report
      # @return [String] report_string
      #
      def convert_report_data(report)
        report_obj_array = Array.new
        runtime_hash = report[:runtime]

        if report[:span_records].any?
          report[:span_records].each do |span|
            span_hash = {:time => span[:timestamp], :sourcetype => "splunktracing:span" }
            span_contents = span.merge(runtime_hash)
            log_array = span_contents.delete(:log_records)
            file = File.open("/Users/gburgett/Downloads/woah.txt", "w")
            file.puts log_array.to_json
            file.close
            runtime_attrs = span_contents.delete(:attrs)
            span_contents[:tags].merge(runtime_attrs)
            span_hash["event"] = span_contents
            report_obj_array.push(span_hash.to_json)
            if log_array && log_array.any?
              span_contents.delete(:timestamp)
              span_contents.delete(:duration)
              log_array.each do |log|
                log_hash = {:time => log[:timestamp_micros]/1000000.0, :sourcetype => "splunktracing:log" , :event => log.merge(span_contents)}
                report_obj_array.push(log_hash.to_json)
              end
            end
          end
        end
        report_string = report_obj_array.join("\n")
        report_string
      end      

      ##
      # @return [Net::HTTP]
      #
      def connection
        unless @connection
          @connection = ::Net::HTTP.new(@host, @port)
          @connection.use_ssl = @encryption == ENCRYPTION_TLS
          @connection.verify_mode = ::OpenSSL::SSL::VERIFY_NONE unless @ssl_verify_peer
          @connection.open_timeout = @open_timeout
          @connection.read_timeout = @read_timeout
          @connection.continue_timeout = @continue_timeout
          @connection.keep_alive_timeout = @keep_alive_timeout
        end
        @connection
      end
    end
  end
end
