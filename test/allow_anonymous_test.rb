require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "allow_anonymous" do
    before do
      @app = app_with_bouncer do
        { allow_anonymous: lambda { |request| request.path == '/allowed' } }
      end
    end

    it "gives access to the requests that fulfill the requirements" do
      get '/allowed'
      assert_equal 'allowed', last_response.body
    end
  
    it "requires authentication to those requests that don't fulfill the requirements" do
      get '/hi'
      assert_requires_authentication
    end
  end
end