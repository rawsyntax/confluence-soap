$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'confluence-soap'
require 'vcr'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

ConfluenceConfig = YAML.load(File.read("config/confluence.yml"))

RSpec.configure do |config|
  config.before(:suite) do
    ignore_request { delete_all_pages_in_test_space }
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'spec/support/vcr_cassettes'
  c.hook_into :webmock # or :fakeweb
end

def delete_all_pages_in_test_space
  client = Savon.client(wsdl: ConfluenceConfig[:url], log: false) do
    convert_request_keys_to :lower_camelcase
  end
  token = client.call(:login, message: {
                        in0: ConfluenceConfig[:user],
                        in1: ConfluenceConfig[:password]
                      }).body[:login_response][:login_return]
  pages = client.call(:get_pages, message: {
                        in0: token,
                        in1: ConfluenceConfig[:space]
                      })
  pages =
    pages.body[:get_pages_response][:get_pages_return][:get_pages_return] || []
  pages = pages.respond_to?(:to_hash) ? [pages] : pages

  pages.each do |page|
    client.call(:remove_page, message: {in0: token, in1: page[:id]})
  end
end

# @note https://github.com/vcr/vcr/issues/181#issuecomment-7016463
def ignore_request
  VCR.turned_off do
    WebMock.allow_net_connect!

    yield

    WebMock.disable_net_connect!
  end
end
