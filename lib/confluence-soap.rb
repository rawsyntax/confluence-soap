require 'savon'

class ConfluenceSoap
  attr_reader :client, :token, :user

  Page = Struct.new(:content, :content_status, :created, :creator, :current, :home_page, :id,
                    :modified, :modifier, :parent_id, :permissions, :space, :title, :url, :version) do
    def self.from_hash h
      self.new *h.values_at(*Page.members.map {|m|m.to_sym})
    end

    SKIPPED_KEYS = [:content_status, :created, :creator, :current, :home_page, :modified, :modifier, :url]
    def to_soap
      to_h.reject {|k,v| v.nil? || SKIPPED_KEYS.include?(k)}
    end
  end

  def initialize url, user, password
    @user = user
    @password = password
    @client = Savon.client(wsdl: url) do
      convert_request_keys_to :lower_camelcase
    end
    @token = login(user, password)
  end

  def login user, password
    response = @client.call :login, message: {in0: user, in1: password}
    @token = response.body[:login_response][:login_return]
  end

  def logout
    @client.call :logout, message: {in0: @token} if @token
  end

  def get_pages space
    response = @client.call :get_pages, message: {in0: @token, in1: space}
    pages = parse_array_response :get_pages, response
    pages.map { |page| Page.from_hash(page) }
  end

  def get_page page_id
    response = @client.call :get_page, message: {in0: @token, in1: page_id}
    Page.from_hash parse_response :get_page, response
  end

  def get_children page_id
    response = @client.call :get_children, message: {in0: @token, in1: page_id}
    pages = parse_array_response :get_children, response
    pages.map { |page| Page.from_hash(page) }
  end

  def store_page page
    response = @client.call :store_page, message: {in0: @token, in1: page.to_soap}
    Page.from_hash parse_response :store_page, response
  end

  def update_page page
    response = @client.call :update_page, message: {in0: @token, in1: page.to_soap, in2: {minorEdit: true}}
    Page.from_hash parse_response :update_page, response
  end

  def remove_page page_id
    response = @client.call :remove_page, message: {in0: @token, in1: page_id}
    Page.from_hash parse_response :remove_page, response
  end

  def search(term, criteria = {})
    limit    = criteria.delete(:limit) || 20
    criteria = criteria.map { |k, v| {key: k, value: v} }
    response =
      @client.call(:search, message: {
                     in0: @token, in1: term, in2: {item: criteria}, in3: limit})
    pages = parse_array_response :search, response
    pages.map { |page| Page.from_hash(page) }
  end

  def has_user user
    response =
      @client.call(:has_user, message: { in0: @token, in1: user })
    parse_response(:has_user, response)
  end

  def execute &block
    yield self
    rescue Savon::SOAPFault => e
      reconnect if e.to_hash[:fault][:faultstring] =~ /InvalidSessionException/
      yield e
  end

  private

  def reconnect
    login(@user, @password)
  end

  def parse_array_response method, response
    parse_response(method, response)["#{method}_return".to_sym] || []
  end

  def parse_response method, response
    response.body["#{method}_response".to_sym]["#{method}_return".to_sym]
  end
end
