require 'resolv'
require 'uri'

class RemoteImageFetch
  # Wrap cURL response as if it's an error
  class UriRestrictions
    def initialize(options = {})
      @schemes = options[:schemes] || ['http', 'https']
      @ports   = options[:ports] || [80, 443, 8080]

      @ip_blacklist = options[:ip_blacklist]
      @host_blacklist = options[:host_blacklist]
    end

    def check(url)
      uri = URI.parse(url)

      check_scheme! uri
      check_port! uri
      check_host! uri

      Resolv.each_address(uri.hostname) do |addr|
        raise "IP blacklisted - #{addr} for #{url}" if ip_blacklist_matches?(addr)
      end
    end

    private

    attr_reader :schemes, :ports, :host_blacklist, :ip_blacklist

    def check_scheme!(uri)
      raise "Scheme rejected: #{uri}" unless schemes.include?(uri.scheme)
    end

    def check_port!(uri)
      raise "Port rejected: #{uri}" unless ports.include?(uri.port)
    end

    def check_host!(uri)
      raise "Host blacklisted: #{uri}" if host_blacklist_matches?(uri)
    end

    def ip_blacklist_matches?(ip)
      return false unless ip_blacklist
      ip_blacklist === ip
    end

    def host_blacklist_matches?(uri)
      return false unless host_blacklist
      host_blacklist === uri.host
    end
  end
end
