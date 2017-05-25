class RemoteImageFetch
  # Wrap Curl::Easy with additional helper methods
  # Can't override initialize() as curb doesn't call it properly.
  class CurlWrap < Curl::Easy
    attr_reader :redirects, :result
    attr_accessor :args, :callback, :redirect, :fetcher

    def setup(fetcher)
      self.follow_location = false
      @fetcher = fetcher
      @redirects = 0

      on_complete(&method(:handle_complete))
      on_redirect(&method(:handle_redirect))
    end

    def body_io
      @body_io ||= StringIO.new(body_str)
    end

    def report(result)
      @result = result
      callback.call(result, *args) if callback
    end

    private

    def handle_complete(*_args)
      case response_code
      when 301, 302, 303
        # handled by handle_redirect
      when 200
        fetcher.report_done(self)
      else
        fetcher.report_failed(self)
      end
      true
    end

    def handle_redirect(*_args)
      @redirects += 1
      fetcher.check_and_redirect(self)
      true
    end
  end
end
