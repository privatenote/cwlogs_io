# frozen_string_literal: true

require_relative 'cwlogs_io/version'
require_relative 'cwlogs_io/io'
require_relative 'hooks'

module CWlogsIO
  def self.new(auth, log_group, log_stream)
    CWlogsIO::IO.new(auth, log_group, log_stream)
  end
end
