# frozen_string_literal: true

module CWlogsIO
  module Utils
    def self.chunks(array, size)
      array.each_slice(size).to_a
    end
  end
end
