require 'curl'

require 'remote_image_fetch/version'
require 'remote_image_fetch/download_result'
require 'remote_image_fetch/curl_error'
require 'remote_image_fetch/curl_wrap'
require 'remote_image_fetch/uri_restrictions'

# RemoteImageFetch
class RemoteImageFetch
  attr_reader :success, :failures

  def initialize(options = {})
    @max_parallel  = options[:max_parallel]  || 16
    @max_redirects = options[:max_redirects] || 4

    @uri_restrictions = RemoteImageFetch::URI_Restrictions.new(options)

    @change_flagged = false
    @core = Curl::Multi.new
    @downloads = []

    @success  = 0
    @failures = 0
  end

  def download(url, *args, &callback)
    curl = CurlWrap.new(url)
    curl.setup self
    curl.args = args
    curl.callback = callback
    downloads.push(curl)
    curl
  end

  def run
    auto_queue!
    core.perform
  end

  def report_done(curl, *_args)
    @change_flagged = true
    @success += 1
    curl.report(DownloadResult::OK.new(curl))
    auto_queue!
  end

  def report_failed(curl, error = nil)
    @change_flagged = true
    @failures += 1
    error ||= CurlError.new(curl)
    curl.report(DownloadResult::Fail.new(curl, error))
    auto_queue!
  end

  def check_and_redirect(curl)
    raise "Too many redirects for #{curl.url}" if curl.redirects > max_redirects
    check_url(curl.redirect_url)
    curl.url = curl.redirect_url
    core.add(curl)
  rescue => e
    report_failed(curl, e)
  end

  private

  attr_reader :uri_restrictions, :downloads, :core,
              :max_parallel, :max_redirects

  def auto_queue!
    loop do
      break if core.requests.size > max_parallel
      break if downloads.empty?

      queue_next!
    end
    @change_flagged = false
  end

  def queue_next!
    get(downloads.pop)
  rescue
    nil
  end

  def check_url(url)
    uri_restrictions.check(url)
  end

  def get(curl)
    check_url(curl.url)
    core.add(curl)
  rescue => e
    report_failed(curl, e)
  end
end
