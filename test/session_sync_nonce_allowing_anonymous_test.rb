require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "session_sync_nonce, allowing anonymous users" do
    before do
      @app = app_with_bouncer do
        {
          session_sync_nonce: 'session_nonce',
          allow_anonymous: lambda { |request| request.path == '/allowed' }
        }
      end
    end

    context "when a user visits a page accessible to anonymous users with a different nonce in the cookie" do
      before do
        set_cookie 'session_nonce=ABC'
        get '/allowed'
      end

      it "triggers a new OAuth dance to synchronize the session" do
        assert_requires_authentication
      end
    end
  end
end