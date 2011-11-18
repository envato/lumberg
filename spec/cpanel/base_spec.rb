require 'spec_helper'
require 'lumberg/whm'
require 'lumberg/cpanel'

module Lumberg
  describe Cpanel::Base do
    before(:each) do
      @login  = { :host => @whm_host, :hash => @whm_hash }
      @server = Whm::Server.new(@login.dup)
      @base   = Cpanel::Base.new(:server => @server, :api_username => "foodawg")
    end

    describe "#initialize" do
      it "requires an api_username" do
        requires_attr("api_username") { Cpanel::Base.new }
      end

      it "assigns api_username param to @api_username" do
        @base.api_username.should == "foodawg"
      end

      context "a server instance or server hash is passed in" do
        it "allows a server instance to be passed in" do
          @base.server.should be_a(Whm::Server)
        end

        it "allows a server hash to be passed in" do
          base = Cpanel::Base.new(:server => @login, :api_username => "foodawg")
          base.server.should be_a(Whm::Server)
        end

        it "caches the server instance" do
          Cpanel::Base.class_variable_get(:@@server).should eql(@base.server)
        end
      end

      context "nothing is passed in" do
        context "a server instance is cached" do
          it "loads the cached server instance" do
            base = Cpanel::Base.new(:api_username => "foodawg")
            base.server.should eql(
              Cpanel::Base.class_variable_get(:@@server)
            )
          end
        end

        context "server instance is not cached" do
          before { Cpanel::Base.class_variable_set(:@@server,nil) }

          it "raises an error" do
            expect {
              Cpanel::Base.new
            }.to raise_error(
              WhmArgumentError, /Missing required param/
            )
          end
        end
      end
    end

    describe "#perform_request" do
      let(:valid_options) {{
        :api_username => "foodawg",
        :api_module   => "SomeModule",
        :api_function => "some_function"
      }}

      context "requires api_username" do
        it "loads saved api_username if api_username not specified" do
          @base.server.should_receive(:perform_request).with(
            anything,
            hash_including(
              :cpanel_jsonapi_module   => "SomeModule",
              :cpanel_jsonapi_func     => "some_function",
              :cpanel_jsonapi_user     => "foodawg"
            )
          )
          @base.perform_request(:api_module => "SomeModule", :api_function => "some_function")
        end

        it "raises error if api_username is not saved" do
          base = @base.dup
          base.api_username = nil

          requires_attr("api_username") {
            base.perform_request(:api_module => "SomeModule", :api_function => "some_function")
          }
        end
      end

      it "requires api_module" do
        requires_attr("api_module") {
          @base.perform_request(:api_username => "foodawg")
        }
      end

      it "requires api_function" do
        requires_attr("api_function") {
          @base.perform_request(:api_username => "foodawg", :api_module => "SomeModule")
        }
      end

      context "optional api_version is specified" do
        it "should perform the request with specified API version" do
          @base.server.should_receive(:perform_request).with(
            anything,
            hash_including(:cpanel_jsonapi_apiversion => 1234)
          )
          @base.perform_request(valid_options.merge(:api_version => 1234))
        end
      end

      context "optional api_version is not specified" do
        it "should set API version to 2" do
          @base.server.should_receive(:perform_request).with(
            anything,
            hash_including(:cpanel_jsonapi_apiversion => 2)
          )
          @base.perform_request(valid_options)
        end
      end

      context "optional key is specified" do
        it "should perform the request with specified key" do
          @base.server.should_receive(:perform_request).with(
            anything,
            hash_including(:key => "some_key")
          )
          @base.perform_request(valid_options.merge(:key => "some_key"))
        end
      end

      context "optional key is not specified" do
        it "should set key to \"cpanelresult\"" do
          @base.server.should_receive(:perform_request).with(
            anything,
            hash_including(:key => "cpanelresult")
          )
          @base.perform_request(valid_options)
        end
      end

      it "should perform the request with \"cpanel\" function" do
        @base.server.should_receive(:perform_request).with("cpanel", anything)
        @base.perform_request(valid_options)
      end

      it "should accept additional call parameters" do
        @base.server.should_receive(:perform_request).with(
          anything,
          hash_including(:awesome => "sauce")
        )
        @base.perform_request(valid_options, { :awesome => "sauce" })
      end

      context "@api_username is not nil" do
        it "uses @api_username as default for api_username param" do
          @base.api_username = "foodawg"
          @base.server.should_receive(:perform_request).with(
            anything,
            hash_including(:cpanel_jsonapi_user => "foodawg")
          )

          options = valid_options
          options.delete(:api_username)
          @base.perform_request(options)
        end
      end
    end

  end
end
