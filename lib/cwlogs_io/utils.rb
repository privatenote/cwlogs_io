# frozen_string_literal: true

module CWlogsIO
  module Utils
    def self.chunks(array, size)
      array.each_slice(size)
    end
  end
end
