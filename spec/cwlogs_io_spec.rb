# frozen_string_literal: true

RSpec.describe CWlogsIO do
  it 'write all messages exactly once, and all messages in a api call have to be ordered in chronological order' do
    client = Aws::CloudWatchLogs::Client.new(stub_responses: true)
    allow(Aws::CloudWatchLogs::Client).to receive(:new).and_return(client)

    io = CWlogsIO.new({ region: 'region', credentials: Aws::Credentials.new('a', 'b') }, 'log_group', 'log_stream')
    thread_count = 100
    events_count_per_thread = 100

    threads = (0...thread_count).map do |thread_id|
      first = thread_id * events_count_per_thread
      last = (thread_id + 1) * events_count_per_thread
      messages = (first...last).map(&:to_s)

      Thread.new do
        messages.each do |message|
          io.write(message)
          sleep 0.01
        end
      end
    end

    threads.each(&:join)

    io.close

    put_log_events_requests = client.api_requests.filter { |r| r[:operation_name] == :put_log_events }
    params = put_log_events_requests.map { |r| r[:params] }
    log_events = params.map { |p| p[:log_events] }

    log_events.each do |events|
      expect(events.map { |event| event[:timestamp] }).to be_monotonically_increasing
    end

    all_messages = log_events.map do |events|
      events.map do |event|
        event[:message]
      end
    end.flatten

    expect(all_messages.uniq.length).to eq(events_count_per_thread * thread_count)
  end

  it 'write all messages even process is forked.' do
    client = Aws::CloudWatchLogs::Client.new(stub_responses: true)
    allow(Aws::CloudWatchLogs::Client).to receive(:new).and_return(client)

    io = CWlogsIO.new({ region: 'region', credentials: Aws::Credentials.new('a', 'b') }, 'log_group', 'log_stream')

    Process.fork do
      io.write('message')
      io.close

      put_log_events_requests = client.api_requests.filter { |r| r[:operation_name] == :put_log_events }
      params = put_log_events_requests.map { |r| r[:params] }
      log_events = params.map { |p| p[:log_events] }

      expect(log_events.length).to eq(1)
    end
  end
end
