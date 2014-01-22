require 'savon'

class ConfluenceSoap
  attr_reader :client, :token

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
    parse_response :get_pages, response
  end

  def get_children page_id
    response = @client.call :get_children, message: {in0: @token, in1: page_id}
    parse_response :get_children, response
  end

  private
  def parse_response method, response
    response.body["#{method}_response".to_sym]["#{method}_return".to_sym]["#{method}_return".to_sym]
  end
end