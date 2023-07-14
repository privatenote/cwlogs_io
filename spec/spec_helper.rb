# frozen_string_literal: true

require 'cwlogs_io'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  RSpec::Matchers.define :be_monotonically_increasing do
    match do |actual|
      derivative = actual.each_cons(2).map { |x, y| y <=> x }
      derivative.all? { |v| v >= 0 }
    end

    failure_message do |actual|
      "expected array #{actual.inspect} to be monotonically increasing"
    end

    failure_message_when_negated do |actual|
      "expected array #{actual.inspect} to not be monotonically increasing"
    end

    description do
      'be monotonically increasing'
    end
  end
end
