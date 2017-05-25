class RemoteImageFetch
  # Wrap cURL response as if it's an error
  class CurlError
    def initialize(curl)
      @curl = curl
    end

    def message
      @curl.status
    end

    def to_s
      message
    end
  end
end
