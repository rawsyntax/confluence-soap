require 'savon'

class ConfluenceSoap
  module Error; end

  attr_reader :client, :token, :user

  Page = Struct.new(:content, :content_status, :created, :creator, :current,
                    :home_page, :id, :modified, :modifier, :parent_id,
                    :permissions, :space, :title, :url, :version) do

    def self.from_hash(h)
      values =
        h.values_at(*Page.members.map { |m| m.to_sym })
        .map { |v| v.is_a?(Hash) ? v[:value] || '' : v }

      self.new *values
    end

    SKIPPED_KEYS = [:content_status, :created, :creator, :current, :home_page,
                    :modified, :modifier, :url]
    def to_soap
      to_h.reject { |k, v| v.nil? || SKIPPED_KEYS.include?(k) }
    end
  end

  def initialize(url, user, password, opts = {})
    opts = opts.merge(wsdl: url)
    @user = user
    @password = password
    @client = Savon.client(opts) do
      convert_request_keys_to :lower_camelcase
    end
    @token = login
  end

  def login
    response = client.call(:login, message: {in0: @user, in1: @password})
    @token = parse_response(:login, response)
  end

  def logout
    client.call(:logout, message: {in0: @token}) if @token
  end

  def get_pages(space)
    response = execute do
      client.call(:get_pages, auth_message({in1: space}))
    end

    pages = parse_array_response(:get_pages, response)
    pages.map { |page| Page.from_hash(page) }
  end

  def get_page(page_id)
    response = execute do
      client.call(:get_page, auth_message({in1: page_id}))
    end

    Page.from_hash(parse_response(:get_page, response))
  end

  def get_children(page_id)
    response = execute do
      client.call(:get_children, auth_message({in1: page_id}))
    end

    pages = parse_array_response(:get_children, response)
    pages.map { |page| Page.from_hash(page) }
  end

  def store_page(page)
    response = execute do
      client.call(:store_page, auth_message({in1: page.to_soap}))
    end

    Page.from_hash(parse_response(:store_page, response))
  end

  def update_page(page)
    response = execute do
      client.call(:update_page,
                  auth_message({in1: page.to_soap, in2: {minorEdit: true} }))
    end

    Page.from_hash(parse_response(:update_page, response))
  end

  def remove_page(page_id)
    response = execute do
      client.call(:remove_page, auth_message({in1: page_id}))
    end

    parse_response(:remove_page, response)
  end

  def search(term, criteria = {})
    limit    = criteria.delete(:limit) || 20
    criteria = criteria.map { |k, v| {key: k, value: v} }
    response = execute do
      client.call(:search,
                  auth_message({in1: term, in2: {item: criteria}, in3: limit}))
    end

    pages = parse_array_response(:search, response)
    pages.map { |page| Page.from_hash(page) }
  end

  def add_label_by_name(label, page_id)
    response = execute do
      client.call(:add_label_by_name, auth_message({in1: label, in2: page_id}))
    end

    parse_response(:add_label_by_name, response)
  end

  def remove_label_by_name(label, page_id)
    response = execute do
      client.call(:remove_label_by_name,
                  auth_message({in1: label, in2: page_id}))
    end

    parse_response(:remove_label_by_name, response)
  end

  def has_user?(user)
    response = execute do
      client.call(:has_user, auth_message({in1: user}))
    end

    parse_response(:has_user, response)
  end

  private

  def execute
    if block_given?
      yield
    else
      tag_errors { raise StandardError.new('requires a block') }
    end
  rescue Exception => e
    if invalid_session?(e)
      reconnect
      # @note necessary for catching an invalid session, and then a
      #   Savon::SOAPFault on the same request
      tag_errors { yield e }
    else
      tag_errors { raise e }
    end
  end

  def invalid_session?(exception)
    if exception.respond_to?(:to_hash)
      fault = exception.to_hash.fetch(:fault) { {} }

      fault[:faultstring] =~ /InvalidSessionException/
    end
  end

  def tag_errors
    yield
  rescue Exception => e
    e.extend(ConfluenceSoap::Error)
    raise
  end

  def reconnect
    @token = login
  end

  def parse_array_response(method, response)
    parsed_response =
      parse_response(method, response)["#{method}_return".to_sym] || []

    parsed_response.respond_to?(:to_hash) ? [parsed_response] : parsed_response
  end

  def auth_message(params = {})
    {message: {in0: @token}.merge(params)}
  end

  def parse_response method, response
    response.body["#{method}_response".to_sym]["#{method}_return".to_sym]
  end
end
