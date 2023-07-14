# CWlogsIO

ruby IO-like streams which is connected to cloudwatch logs.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add cwlogs_io

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install cwlogs_io

## Usage

```ruby

credentials = Aws::InstanceProfileCredentials.new
credentials = Aws::SharedCredentials.new
credentials = Aws::Credentials.new
auth = {
    region: 'ap-northeast-2'
    credentials: Aws::InstanceProfileCredentials.new
}

log_group = 'foo'
log_stream = 'bar'

logger = Logger.new(CWlogsIO.new(auth, log_group, log_stream))
logger.info('hello with CWlogsIO')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/privatenote/cwlogs_io.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
