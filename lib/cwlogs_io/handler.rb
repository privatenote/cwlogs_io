# frozen_string_literal: true

require 'set'
require 'singleton'
require 'concurrent/executor/single_thread_executor'

module CWlogsIO
  class HandlerWrapper
    def initialize(handler)
      @handler = handler
    end

    def self.create(handler_class, *params)
      handler = HandlerWrapper.new(handler_class.new(*params))
      HandlerManager.instance.register(handler)
      handler
    end

    def close
      @handler.close
      HandlerManager.instance.deregister(self)
    end

    def method_missing(method, *params)
      @handler.send(method, *params)
    end

    def respond_to_missing?(method, include_private = false)
      @handler.respond_to?(method, include_private)
    end
  end

  class HandlerManager
    include Singleton

    def initialize
      @handlers = Set.new
    end

    def respawn_all
      @handlers.each(&:respawn)
    end

    def register(handler)
      @handlers << handler
    end

    def deregister(handler)
      @handlers.delete(handler)
    end
  end

  class Handler
    DEFAULT_POLLING_PERIOD_IN_SECONDS = 1
    TERMINATION_TIMEOUT_IN_SECONDS = 5

    def initialize(logger, polling_period = nil)
      @queue = Queue.new
      @logger = logger
      @polling_period = polling_period || DEFAULT_POLLING_PERIOD_IN_SECONDS

      initialize_executor
    end

    def enq(event)
      return if closed?

      @queue << event
    end

    def <<(event)
      enq(event)
    end

    def close
      return if closed?

      @queue.close

      shutdown_executor
    end

    def closed?
      @queue.closed?
    end

    # should be called in child process, not parent.
    # or, you may lose some events.
    def respawn
      return if closed?

      @queue.clear
      initialize_executor
    end

    private

    def initialize_executor
      @executor = Concurrent::SingleThreadExecutor.new
      @executor.post do
        serve
      end
    end

    def shutdown_executor
      @executor.shutdown
      @executor.wait_for_termination(TERMINATION_TIMEOUT_IN_SECONDS)
      @executor.kill unless @executor.shutdown?
    end

    def serve
      @logger.info('ready to process')
      until @queue.closed?
        handle_all

        sleep @polling_period
      end

      handle_all unless @queue.empty?
      @logger.info('quitting...')
    rescue Exception => e
      @logger.error(e)
    end

    def pop_all_events
      result = []
      result << @queue.pop until @queue.empty?
      result
    end

    def handle_all
      process_events(pop_all_events) unless @queue.empty?
    end

    def process_events(events)
      raise NotImplementedError
    end
  end
end
