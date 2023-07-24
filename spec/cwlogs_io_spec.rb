# frozen_string_literal: true

def log_events(client)
  put_log_events_requests = client.api_requests.filter { |r| r[:operation_name] == :put_log_events }
  params = put_log_events_requests.map { |r| r[:params] }
  params.map { |p| p[:log_events] }
end

def log_messages(client)
  log_events(client).map do |events|
    events.map do |event|
      event[:message]
    end
  end.flatten
end

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

    log_events(client).each do |events|
      expect(events.map { |event| event[:timestamp] }).to be_monotonically_increasing
    end

    expect(log_messages(client).uniq.length).to eq(events_count_per_thread * thread_count)
  end

  describe 'HandlerManager#respawn_all' do
    it 'write all messages even "fork" called' do
      client = Aws::CloudWatchLogs::Client.new(stub_responses: true)
      allow(Aws::CloudWatchLogs::Client).to receive(:new).and_return(client)

      io = CWlogsIO.new({ region: 'region', credentials: Aws::Credentials.new('a', 'b') }, 'log_group', 'log_stream')

      Process.fork do
        CWlogsIO::HandlerManager.instance.respawn_all
        io.write('message')
        io.close

        expect(log_events(client).length).to eq(1)
      end
    end

    it 'messages requested before "fork" should be delivered by parent' do
      client = Aws::CloudWatchLogs::Client.new(stub_responses: true)
      allow(Aws::CloudWatchLogs::Client).to receive(:new).and_return(client)

      io = CWlogsIO.new({ region: 'region', credentials: Aws::Credentials.new('a', 'b') }, 'log_group', 'log_stream')

      count_of_event = 5000

      count_of_event.times.each do |i|
        io.write(i.to_s)
      end

      Process.fork do
        CWlogsIO::HandlerManager.instance.respawn_all

        io.close
        expect(log_messages(client).length).to eq(0)
      end

      io.close
      expect(log_messages(client).length).to eq(count_of_event)
    end
  end
end
