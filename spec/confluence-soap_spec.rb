require 'spec_helper'

describe ConfluenceSoap do
  let (:url) {'http://example.com?wsdl'}
  subject {ConfluenceSoap.new(url, 'user', 'password')}

  describe 'Page' do
    ConfluenceSoap::Page.new.to_h
  end

  describe '#initialize' do
    it 'should create a savon soap client with url provided' do
      Savon.should_receive(:client).with(wsdl: url)
      ConfluenceSoap.any_instance.should_receive(:login)

      subject
    end
  end

  describe '#login' do
    before (:each) do
      Savon::Client.any_instance.should_receive(:call).twice
        .with(:login, message: {in0: 'user', in1: 'password'})
        .and_return(double(:response, body: {login_response: {login_return: 'token'}}))
    end

    it 'should login with savon client' do

      subject.login('user', 'password')
    end

    it 'should store the login token' do
      subject.login('user', 'password')

      subject.token.should == 'token'
    end
  end

  describe '#get_pages' do
    let(:space) { 'SpaceName' }
    before (:each) do
      ConfluenceSoap.any_instance.stub(:login).and_return('token')
      subject.client.should_receive(:call)
        .with(:get_pages, message: {in0: 'token', in1: space})
        .and_return(double(:response, body: {get_pages_response: {get_pages_return: {get_pages_return: []}}}))
    end

    it 'should return the pages in the space' do
      subject.get_pages(space).should == []
    end
  end

  describe '#get_page' do
    let(:page_id) { '123456' }
    before (:each) do
      ConfluenceSoap.any_instance.stub(:login).and_return('token')
      subject.client.should_receive(:call)
        .with(:get_page, message: {in0: 'token', in1: page_id})
        .and_return(double(:response, body: {get_page_response: {get_page_return: {}}}))
    end

    it 'should return the page' do
      subject.get_page page_id
    end
  end

  describe '#get_page' do
    let(:page_id) { '123456' }
    before (:each) do
      ConfluenceSoap.any_instance.stub(:login).and_return('token')
      subject.client.should_receive(:call)
        .with(:remove_page, message: {in0: 'token', in1: page_id})
        .and_return(double(:response, body: {remove_page_response: {remove_page_return: {}}}))
    end

    it 'should return the page' do
      subject.remove_page page_id
    end
  end
  describe '#get_children' do
    before (:each) do
      ConfluenceSoap.any_instance.stub(:login).and_return('token')
      subject.client.should_receive(:call)
        .with(:get_children, message: {in0: 'token', in1: 'page_id'})
        .and_return(double(:response, body: {get_children_response: {get_children_return: {get_children_return: []}}}))
    end

    it 'should return array of child pages' do
      subject.get_children('page_id').should == []
    end
  end

  describe '#store_page' do
    let(:page) do
      ConfluenceSoap::Page.from_hash({content: 'test', title: 'Testing API ', space: 'Space Name',
                                     parent_id: 'parent_id', permissions: 0})
    end

    before (:each)  do
      ConfluenceSoap.any_instance.stub(:login).and_return('token')
      subject.client.should_receive(:call)
        .with(:store_page, message: {in0: 'token', in1: {content: 'test', title: 'Testing API ',
                                      space: 'Space Name', parent_id: 'parent_id', permissions: 0}})
        .and_return(double(:response, body: {store_page_response: {store_page_return: {}}}))
    end

    it 'should store page with savon' do
      subject.store_page(page)
    end
  end

  describe '#update_page' do
    let(:page) do
      ConfluenceSoap::Page.from_hash({content: 'test', title: 'Testing API ', space: 'Space Name',
                                     parent_id: 'parent_id', permissions: 0})
    end

    before (:each)  do
      ConfluenceSoap.any_instance.stub(:login).and_return('token')
      subject.client.should_receive(:call)
        .with(:update_page, message: {in0: 'token', in1: {content: 'test', title: 'Testing API ',
                                      space: 'Space Name', parent_id: 'parent_id', permissions: 0},
                                      in2: {minorEdit: true}})
        .and_return(double(:response, body: {update_page_response: {update_page_return: {}}}))
    end

    it 'should store page with savon' do
      subject.update_page(page)
    end
  end

  describe '#search' do
    let(:term) { 'search term' }
    let(:criteria) { {item: [{key: :space_key, value: 'SpaceName'}]} }
    before (:each)  do
      ConfluenceSoap.any_instance.stub(:login).and_return('token')
      subject.client.should_receive(:call)
        .with(:search,
              message: {in0: 'token', in1: term, in2: criteria, in3: 20})
        .and_return(double(:response, body: {search_response: {search_return: {search_return: []}}}))
    end

    it 'should search with savon' do
      subject.search(term, space_key: 'SpaceName').should == []
    end
  end

  describe '#execute' do
    before (:each)  do
      ConfluenceSoap.any_instance.stub(:login).and_return('token')
      subject.should_receive(:login)
    end

    it 'should reconnect when session is invalid' do
      Savon::SOAPFault.any_instance.stub(:to_hash).and_return({fault: {faultstring: 'InvalidSessionException'}})
      ex = Savon::SOAPFault.new nil, nil
      subject.execute do |x|
        raise ex if x.is_a? ConfluenceSoap
      end
    end
  end
end
