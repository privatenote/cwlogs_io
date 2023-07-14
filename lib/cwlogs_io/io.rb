# frozen_string_literal: true

require 'aws-sdk-cloudwatchlogs'
require 'json/ext'
require 'logger'
require_relative 'log_event'
require_relative 'utils'
require_relative 'handler'
require_relative 'client'

module CWlogsIO
  class LogEventHandler < Handler
    def initialize(client, log_group, log_stream, logger, polling_rate = nil)
      super(logger, polling_rate)
      @client = client
      @log_group = log_group
      @log_stream = log_stream
    end

    def process_events(events)
      events.sort_by!(&:timestamp)
      Utils.chunks(events, 100).each do |event_chunk|
        send_events(event_chunk)
      end
    end

    private

    def send_events(events)
      return if events.empty?

      @client.put_log_events(events)
    rescue StandardError => e
      @logger.error(e)
    end
  end

  class IO
    def initialize(auth, log_group, log_stream)
      @auth = auth
      @log_group = log_group
      @log_stream = log_stream
      @handler = LogEventHandler.new(client, log_group, log_stream, logger)
      @handler.close if !ensure_log_group || !ensure_log_stream
    end

    def write(message)
      @handler << LogEvent.new(message, Time.now)
    end

    def close
      @handler.close
    end

    private

    def client
      @client ||= Client.new(@auth, @log_group, @log_stream)
    end

    def ensure_log_group
      client.create_log_group
      true
    rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
      true
    rescue Aws::CloudWatchLogs::Errors::ServiceError => e
      logger.error(e)
      false
    end

    def ensure_log_stream
      client.create_log_stream
      true
    rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
      true
    rescue Aws::CloudWatchLogs::Errors::ServiceError => e
      logger.error(e)
      false
    end

    def logger
      @@logger ||= Logger.new($stdout)
    end
  end
end
