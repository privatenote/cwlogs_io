# frozen_string_literal: true

require 'concurrent/executor/single_thread_executor'

module CWlogsIO
  class Handler
    DEFAULT_POLLING_PERIOD_IN_SECONDS = 1
    TERMINATION_TIMEOUT_IN_SECONDS = 5

    def initialize(logger, polling_period = nil)
      @executor = Concurrent::SingleThreadExecutor.new
      @queue = Queue.new
      @logger = logger
      @polling_period = polling_period || DEFAULT_POLLING_PERIOD_IN_SECONDS

      @executor.post do
        serve
      end
    end

    def enq(event)
      return if @queue.closed?

      @queue << event
    end

    def <<(event)
      enq(event)
    end

    def close
      return if @queue.closed?

      @queue.close
      @executor.shutdown
      @executor.wait_for_termination(TERMINATION_TIMEOUT_IN_SECONDS)
      @executor.kill unless @executor.shutdown?
    end

    private

    def serve
      @logger.info('ready to process')
      until @queue.closed?
        handle_all

        sleep @polling_period
      end

      handle_all unless @queue.empty?
      @logger.info('quitting...')
    end

    def pop_all_events
      result = []
      result << @queue.pop until @queue.empty?
      result
    end

    def handle_all
      process_events(pop_all_events)
    end
  end
end
