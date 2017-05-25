require 'spec_helper'

RSpec.describe RemoteImageFetch do
  let(:options) { {} }
  let(:url) { 'https://www.google.com/' }
  subject { described_class.new(options) }

  it 'has a version number' do
    expect(RemoteImageFetch::VERSION).not_to be nil
  end

  context 'with a normal, safe URL' do
    it 'does basic download' do
      fetch = subject.download(url)
      subject.run
      result = fetch.result

      expect(result.ok?).to be true
      expect(subject.success).to eq(1)
      expect(subject.failures).to eq(0)
      expect(result.io.read).to match(/Google/)
    end

    it 'does multiple downloads' do
      fetches = []
      10.times do
        fetches << subject.download(url)
      end
      subject.run
      results = fetches.map(&:result)

      expect(results.all?(&:ok?)).to be true
      expect(subject.success).to eq(10)
      expect(subject.failures).to eq(0)
      expect(results[0].io.read).to match(/Google/)
    end
  end

  context 'when accessing a local IP' do
    let(:options) { { ip_blacklist: /^(127\.0\.0|10|192\.168)\./ } }
    it 'should return an error' do
      fetch = subject.download('https://192.168.2.10/')
      subject.run
      result = fetch.result
      expect(result.ok?).to be false
      expect(subject.success).to eq(0)
      expect(subject.failures).to eq(1)
      expect(result.error_message).to match(/IP blacklisted/)
    end
  end

  context 'when accessing a banned domain' do
    let(:options) { { :host_blacklist => /malwarez.ru$/ } }
    it 'refuses to access the domain' do
      fetch = subject.download('https://funky.malwarez.ru/')
      subject.run
      result = fetch.result
      expect(result).to be_error
      expect(result.error_message).to match(/Host blacklisted/)
      expect(subject.success).to eq 0
      expect(subject.failures). to eq 1
    end
  end
end
