require 'savon'

class ConfluenceSoap
  attr_reader :client, :token

  Page = Struct.new(:content, :contentStatus, :title, :space, :parentId, :permissions)

  def initialize url, user, password
    @client = Savon.client(wsdl: url)
    @token = login(user, password)
  end

  def login user, password
    response = @client.call :login, message: {in0: user, in1: password}
    @token = response.body[:login_response][:login_return]
  end

  def get_pages space
    response = @client.call :get_pages, message: {in0: @token, in1: space}
    parse_array_response :get_pages, response
  end

  def get_page page_id
    response = @client.call :get_page, message: {in0: @token, in1: page_id}
    parse_response :get_page, response
  end

  def get_children page_id
    response = @client.call :get_children, message: {in0: @token, in1: page_id}
    parse_array_response :get_children, response
  end

  def store_page page
    response = @client.call :store_page, message: {in0: @token, in1: page.to_h}
    parse_response :store_page, response
  end

  private

  def parse_array_response method, response
    parse_response(method, response)["#{method}_return".to_sym]
  end

  def parse_response method, response
    response.body["#{method}_response".to_sym]["#{method}_return".to_sym]
  end
end
