
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
      debug("Starting processing of #{titles} from #{is} to #{should}")
      yield
      notice("Finished processing #{titles} in #{format_seconds(Time.now - start_time)} seconds: #{should}")
    rescue StandardError => e
      err("Failed processing #{titles} after #{format_seconds(Time.now - start_time)} seconds: #{e}")
      raise
    ensure
      @context = nil
    end
  end

  def attribute_changed(title, attribute, is, should, message: nil)
    printable_is = 'nil'
    printable_should = 'nil'
    if is
      printable_is = is.is_a?(Numeric) ? is : "'#{is}'"
    end
    if should
      printable_should = should.is_a?(Numeric) ? should : "'#{should}'"
    end
    notice("#{title}: attribute '#{attribute}' changed from #{printable_is} to #{printable_should}#{message ? ": #{message}" : ''}")
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
