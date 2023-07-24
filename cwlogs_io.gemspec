# frozen_string_literal: true

require_relative 'lib/cwlogs_io/version'

Gem::Specification.new do |spec|
  spec.name = 'cwlogs_io'
  spec.version = CWlogsIO::VERSION
  spec.authors = ['Hyeonjun Lee']
  spec.email = ['hyeonjun.lee@privatenote.co.kr']

  spec.summary = 'IO-like streams for CloudWatch Logs.'
  spec.homepage = 'https://github.com/privatenote/cwlogs_io'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/privatenote/cwlogs_io'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'aws-sdk-cloudwatchlogs', '~> 1.69'
  spec.add_dependency 'aws-sdk-core', '~> 3'
  spec.add_dependency 'concurrent-ruby', '~> 1.2'
  spec.add_dependency 'nokogiri', '~> 1.15'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
