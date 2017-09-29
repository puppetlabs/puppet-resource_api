
class Puppet::ResourceApi::BaseContext
  def initialize(typename)
    @typename = typename
  end

  [:debug, :info, :notice, :warning, :err].each do |level|
    define_method(level) do |*args|
      if args.length == 1
        message = "#{@context || @typename}: #{args.last}"
      elsif args.length == 2
        resources = format_titles(args.first)
        message = "#{resources}: #{args.last}"
      else
        message = args.map(&:to_s).join(', ')
      end
      send_log(level, message)
    end
  end

  [:creating, :updating, :deleting, :failing].each do |method|
    define_method(method) do |titles, message: method.to_s.capitalize, &block|
      start_time = Time.now
      setup_context(titles, message)
      begin
        debug('Start')
        block.call
        notice("Finished in #{format_seconds(Time.now - start_time)} seconds")
      rescue StandardError => e
        err("Failed after #{format_seconds(Time.now - start_time)} seconds: #{e}")
        raise
      ensure
        @context = nil
      end
    end
  end

  def processing(titles, is, should, message: 'Processing')
    start_time = Time.now
    setup_context(titles, message)
    begin
      debug("Changing #{is.inspect} to #{should.inspect}")
      yield
      notice("Changed from #{is.inspect} to #{should.inspect} in #{format_seconds(Time.now - start_time)} seconds")
    rescue
      err("Failed changing #{is.inspect} to #{should.inspect} after #{format_seconds(Time.now - start_time)} seconds")
      raise
    ensure
      @context = nil
    end
  end

  def attribute_changed(titles, is, should, message: nil)
    setup_context(titles, message)
    notice("Changed from #{is.inspect} to #{should.inspect}")
  end

  def send_log(_level, _message)
    raise 'Received send_log() on an unprepared BaseContext. Use IOContext, or PuppetContext instead.'
  end

  private

  def format_titles(titles)
    if titles.length.zero? && !titles.is_a?(String)
      @typename
    else
      "#{@typename}[#{[titles].flatten.compact.join(', ')}]"
    end
  end

  def setup_context(titles, message = nil)
    @context = format_titles(titles)
    @context += ": #{message}: " if message
  end

  def format_seconds(seconds)
    return '%.6f' % seconds if seconds < 1
    '%.2f' % seconds
  end
end
