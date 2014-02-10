require 'spec_helper'

describe ConfluenceSoap do
  let (:url) { ConfluenceConfig[:url] }
  let(:space) { ConfluenceConfig[:space] }
  let(:page) do
    ConfluenceSoap::Page.from_hash({content: 'test', title: 'Testing API ',
                                     space: ConfluenceConfig[:space],
                                     permissions: 0})
  end

  subject do
    ConfluenceSoap.new(url, ConfluenceConfig[:user],
                       ConfluenceConfig[:password],
                       log: false)

  end

  shared_context 'invalidate session to force a reconnect' do
    before(:each) do
      ignore_request do
        @token = subject.token

        subject.client.stub(:call)
          .and_return(double(body:
                             {login_response:
                               {login_return: 'invalid_token'}}))
        subject.login
        subject.client.unstub(:call)
        subject.stub(:login).and_return(@token)
      end
    end
  end


  describe '#initialize' do
    it 'creates a savon soap client with url provided' do
      ConfluenceSoap.any_instance.should_receive(:login)
      Savon.should_receive(:client)

      subject
    end
  end

  context 'when #login repeatedly fails' do
    it 'should raise the library error' do
      ConfluenceSoap.any_instance.stub(:login).and_return('invalid-token')

      VCR.use_cassette(:repeated_login_failures) do
        lambda {
          subject.get_pages(space)
        }.should raise_error(ConfluenceSoap::Error)
      end
    end
  end

  describe '#login' do
    it 'stores the session token' do
      VCR.use_cassette(:login) do
        subject.login
      end

      subject.token.should_not be_nil
    end
  end

  describe 'with an authenticated user' do
    include_context 'invalidate session to force a reconnect'

    describe '#store_page' do
      it 'stores the page and returns it' do
        ignore_request do
          subject.store_page(page).should be_instance_of(ConfluenceSoap::Page)
        end
      end

      context 'when the page already exists' do
        it 'should raise the library error' do
          ignore_request do
            lambda { subject.store_page(page) }
              .should raise_error(ConfluenceSoap::Error)
          end
        end
      end
    end

    describe '#get_pages' do
      it 'should return the pages in the space' do
        VCR.use_cassette(:get_pages) do
          subject.get_pages(space).size.should == 1
        end
      end
    end

    describe '#get_page' do
      it 'should return the page' do
        VCR.use_cassette(:get_first_page) do
          subject.get_pages(space).first.id.should_not be_nil
        end
      end
    end

    describe '#get_children' do
      it 'should return array of child pages' do
        VCR.use_cassette(:get_first_page_id) do
          @page_id = subject.get_pages(space).first.id
        end

        VCR.use_cassette(:get_children) do
          subject.get_children(@page_id).should == []
        end
      end
    end

    describe '#update_page' do
      it 'should store page with savon' do
        ignore_request do
          @page = subject.get_pages(space).first
        end

        VCR.use_cassette(:update_page) do
          @page.content = 'my edits'
          subject.update_page(@page).should be_instance_of(ConfluenceSoap::Page)
        end
      end
    end

    describe '#search' do
      it 'should search with savon' do
        VCR.use_cassette(:search_without_results) do
          subject.search('Intridea',
                         {type: 'page', spaceKey: ConfluenceConfig[:space]})
            .should == []
        end
      end
    end

    describe '#add_label_by_name' do
      it 'should add a label to the page' do
        ignore_request do
          page_id = subject.get_pages(space).first.id

          subject.add_label_by_name('faq', page_id).should == true
        end
      end
    end

    describe '#remove_label_by_name' do
      it 'should remove a label from the page' do
        ignore_request do
          page_id = subject.get_pages(space).first.id

          subject.remove_label_by_name('faq', page_id).should == true
        end
      end
    end

    describe '#remove_page' do
      it 'should remove the page' do
        ignore_request do
          page_id = subject.get_pages(space).first.id

          subject.remove_page(page_id).should == true
        end
      end
    end
  end
end
