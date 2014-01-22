require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ConfluenceSoap" do
  let (:url) {"http://example.com?wsdl"}
  subject {ConfluenceSoap.new(url, 'user', 'password')}

  describe "#initialize" do
    it "should create a savon soap client with url provided" do
      Savon.should_receive(:client).with(wsdl: url)
      ConfluenceSoap.any_instance.should_receive(:login)

      subject
    end
  end

  describe "#login" do
    before (:each) {
      Savon::Client.any_instance.should_receive(:call).twice
        .with(:login, message: {in0: 'user', in1: 'password'})
        .and_return(double(:response, body: {login_response: {login_return: 'token'}}))
    }
    it "should login with savon client" do

      subject.login('user', 'password')
    end

    it "should store the login token" do
      subject.login('user', 'password')

      subject.token.should == 'token'
    end
  end

  describe "#get_children" do
    before (:each) {
      ConfluenceSoap.any_instance.stub(:login).and_return("token")
      subject.client.should_receive(:call)
        .with(:get_children, message: {in0: 'token', in1: 'page_id'})
        .and_return(double(:response, body: {get_children_response: {get_children_return: {get_children_return: []}}}))
    }
    it "should login if there is no token" do
      subject.get_children('page_id').should == []
    end
  end
  
end
