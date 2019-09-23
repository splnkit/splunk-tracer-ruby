require 'forwardable'
require 'logger'

# Splunk Tracer
module SplunkTracing
  extend SingleForwardable

  # Base class for all SplunkTracing errors
  class Error < StandardError; end

  # Returns the singleton instance of the Tracer.
  def self.instance
    SplunkTracing::GlobalTracer.instance
  end

  def_delegator :instance, :configure
  def_delegator :instance, :start_span
  def_delegator :instance, :start_active_span
  def_delegator :instance, :disable
  def_delegator :instance, :enable
  def_delegator :instance, :flush

  # Convert a time to microseconds
  def self.micros(time)
    (time.to_f * 1E6).floor
  end

  # Returns a random guid. Note: this intentionally does not use SecureRandom,
  # which is slower and cryptographically secure randomness is not required here.
  def self.guid
    unless @_lastpid == Process.pid
      @_lastpid = Process.pid
      @_rng = Random.new
    end
    @_rng.bytes(8).unpack('H*')[0]
  end

  def self.logger
    @logger ||= defined?(::Rails) ? Rails.logger : Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @logger = logger
  end
end

require 'splunktracing/tracer'
require 'splunktracing/global_tracer'
require 'splunktracing/scope'
require 'splunktracing/scope_manager'
