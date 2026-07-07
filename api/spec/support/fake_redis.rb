class FakeRedis
  def initialize
    @store = {}
  end

  def get(key)
    value = @store[key]
    value.nil? ? nil : value.to_s
  end

  def incr(key)
    @store[key] = @store.fetch(key, 0).to_i + 1
  end

  def multi
    yield self
    self
  end

  def keys(pattern)
    regex = Regexp.new("\\A#{Regexp.escape(pattern).gsub('\*', '.*')}\\z")
    @store.keys.grep(regex)
  end

  def flushdb
    @store.clear
  end
end
