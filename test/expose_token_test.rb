require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "expose_token: true" do
    before do
      @app = app_with_bouncer do
        {
          expose_token: true
        }
      end
    end

    context "after a successful OAuth dance" do
      before do
        get '/hi'
        follow_successful_oauth!
      end

      it "exposes the token" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert last_request.env['bouncer.token']
        assert_equal 'hi', last_response.body
      end
    end
  end

  context "expose_token: false" do
    before do
      @app = app_with_bouncer do
        {
          expose_token: false
        }
      end
    end

    context "after a successful OAuth dance" do
      before do
        get '/hi'
        follow_successful_oauth!
      end

      it "does not expose the token" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert last_request.env['bouncer.token'].nil?
        assert_equal 'hi', last_response.body
      end
    end
  end
end