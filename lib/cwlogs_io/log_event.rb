# frozen_string_literal: true

module CWlogsIO
  class LogEvent
    attr_reader :message, :timestamp

    def initialize(message, timestamp)
      @message = message
      @timestamp = timestamp
    end
  end
end
