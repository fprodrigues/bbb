class FakeRedis
  def initialize
    @store = {}
  end

  def get(key)
    @store[key]
  end

  def incr(key)
    @store[key] = (@store[key].to_i + 1).to_s
  end

  def del(key)
    @store.delete(key)
  end

  def multi
    yield self
  end

  def keys(pattern)
    regex = glob_to_regex(pattern)
    @store.keys.grep(regex)
  end

  def scan_each(match:)
    keys(match).each { |key| yield key }
  end

  private

  def glob_to_regex(pattern)
    Regexp.new(
      "^" + pattern.gsub(".", '\.').gsub("*", ".*") + "$"
    )
  end
end
