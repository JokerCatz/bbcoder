require 'bbcoder'

module BBCoderHelper
  # Parses all bbcode in +text+ and returns a new HTML-formatted string.
  def bbcoder_encode(text)
    BBCoder.encode(text)
  end
  def bbcoder_decode(text)
    BBCoder.decode(text)
  end
end