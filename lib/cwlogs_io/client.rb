# frozen_string_literal: true

require 'aws-sdk-cloudwatchlogs'

module CWlogsIO
  class Client
    def initialize(auth, log_group, log_stream)
      @auth = auth
      @log_group = log_group
      @log_stream = log_stream
    end

    def create_log_group
      client.create_log_group({ log_group_name: @log_group })
    end

    def create_log_stream
      client.create_log_stream(
        {
          log_group_name: @log_group,
          log_stream_name: @log_stream,
        }
      )
    end

    def put_log_events(log_events)
      client.put_log_events(
        {
          log_events: to_params(log_events),
          log_group_name: @log_group,
          log_stream_name: @log_stream,
        }
      )
    end

    private

    def client
      @client ||= Aws::CloudWatchLogs::Client.new(
        region: @auth[:region],
        credentials: @auth[:credentials],
      )
    end

    def to_params(events)
      events.map do |event|
        {
          message: event.message,
          timestamp: (event.timestamp.to_f * 1000).to_i
        }
      end
    end
  end
end
