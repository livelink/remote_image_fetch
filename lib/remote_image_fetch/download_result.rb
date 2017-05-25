class DownloadResult
  # Remote download succeeded
  class OK < DownloadResult
    def initialize(curl)
      @curl = curl
    end

    def io
      curl.body_io
    end
  end

  # Remote download failed
  class Fail < DownloadResult
    def initialize(curl, error)
      @curl = curl
      @error = error
    end

    def error_message
      @error.to_s
    end
  end

  attr_reader :curl

  def ok?
    is_a?(OK)
  end

  def error?
    is_a?(Fail)
  end

  def http_status
    curl.response_code
  end
end
