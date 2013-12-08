require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "expose_user: true" do
    before do
      @app = app_with_bouncer do
        {
          oauth: { id: '46307a2b-0397-4739-b2b7-2f67d1cff597', secret: '46307a2b-0397-4739-b2b7-2f67d1cff597' },
          secret: ENV['HEROKU_BOUNCER_SECRET'],
          expose_user: true
        }
      end
    end

    context "after a successful OAuth dance" do
      before do
        get '/hi'
        follow_successful_oauth!
      end

      it "exposes the user" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert_equal %w{ allow_tracking email id oauth_token}, last_request.env['bouncer.user'].keys.sort
        assert_equal 'hi', last_response.body
      end
    end
  end

  context "expose_user: false" do
    before do
      @app = app_with_bouncer do
        {
          oauth: { id: '46307a2b-0397-4739-b2b7-2f67d1cff597', secret: '46307a2b-0397-4739-b2b7-2f67d1cff597' },
          secret: ENV['HEROKU_BOUNCER_SECRET'],
          expose_user: false
        }
      end
    end

    context "after a successful OAuth dance" do
      before do
        get '/hi'
        follow_successful_oauth!
      end

      it "does not expose the user, exposing a `true` boolean value instead" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert_equal true, last_request.env['bouncer.user']
        assert_equal 'hi', last_response.body
      end
    end
  end
end