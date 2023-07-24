# frozen_string_literal: true

RSpec.describe CWlogsIO::Utils do
  it 'split array into chunks which length is n' do
    chunk_size = 100
    arr = (1...1010).to_a
    chunks = CWlogsIO::Utils.chunks(arr, chunk_size).to_a
    chunks_without_last = chunks[0..-2]
    last_chunk = chunks[-1]

    total_length = chunks.map(&:length).sum

    expect(total_length).to eq(arr.length)
    chunks_without_last.each do |chunk|
      expect(chunk.length).to be(chunk_size)
    end
    expect(last_chunk.length).to be <= chunk_size
  end
end
