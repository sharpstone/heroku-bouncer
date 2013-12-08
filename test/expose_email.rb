require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "expose_email: true" do
    before do
      @app = app_with_bouncer do
        { expose_email: true }
      end
    end

    context "after a successful OAuth dance" do
      before do
        get '/hi'
        follow_successful_oauth!
      end

      it "exposes the email" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert last_request.env['bouncer.email']
        assert_equal 'hi', last_response.body
      end
    end
  end

  context "expose_email: false" do
    before do
      @app = app_with_bouncer do
        {
          expose_email: false
        }
      end
    end

    context "after a successful OAuth dance" do
      before do
        get '/hi'
        follow_successful_oauth!
      end

      it "does not expose the email" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert last_request.env['bouncer.email'].nil?
        assert_equal 'hi', last_response.body
      end
    end
  end
end