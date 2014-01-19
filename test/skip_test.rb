require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "skip" do
    before do
      @app = app_with_bouncer do
        { skip: lambda { |env| env['PATH_INFO'] == '/skip-me' } }
      end
    end

    it "skips bouncer for the requests that fulfill the requirements" do
      get '/skip-me'
      assert_equal 'skip-me', last_response.body
      assert last_response.headers['Set-Cookie'].nil?
    end

    it "applies bouncer to those requests that don't fulfill the requirements" do
      get '/hi'
      assert_requires_authentication
      assert !last_response.headers['Set-Cookie'].nil?
    end
  end
end