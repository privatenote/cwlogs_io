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
    # https://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
    # The maximum batch size is 1,048,576 bytes, and this size is calculated as the sum of all event messages in UTF-8, plus 26 bytes for each log event.
    # 26 bytes is the length of the JSON structure that surrounds the log event information:
    # Each log event can be no larger than 256 KB.
    # The maximum number of log events in a batch is 10,000
    # When there are 100 events in one chunk, the average size of each event can be up to a maximum of 10kB.
    EVENTS_PER_CHUNK = 100

    def initialize(client, log_group, log_stream, logger, polling_rate = nil)
      super(logger, polling_rate)
      @client = client
      @log_group = log_group
      @log_stream = log_stream
    end

    def process_events(events)
      events.sort_by!(&:timestamp)
      Utils.chunks(events, EVENTS_PER_CHUNK).each do |event_chunk|
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

  # ruby 'logger' compatible IO-like class.
  # it should implement #write, #close method.
  # https://github.com/ruby/logger/blob/master/lib/logger/log_device.rb
  class IO
    def initialize(auth, log_group, log_stream)
      @auth = auth
      @log_group = log_group
      @log_stream = log_stream
      @handler = LogEventHandler.new(client, log_group, log_stream, logger)
      close if !ensure_log_group || !ensure_log_stream

      at_exit do
        close
      end
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
