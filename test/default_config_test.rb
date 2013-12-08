require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "the default configuration" do

    before do
      @app = app_with_bouncer do
        {
          oauth: { id: '46307a2b-0397-4739-b2b7-2f67d1cff597', secret: '46307a2b-0397-4739-b2b7-2f67d1cff597' },
          secret: ENV['HEROKU_BOUNCER_SECRET']
        }
      end
    end

    context "on any request not related with authentication" do
      it "requires authentication via /auth/heroku, which gets managed by omniauth-heroku" do
        get '/hi'
        assert 302, last_response.status
        assert_equal "http://#{app_host}/auth/heroku", last_response.location
      end

      context "after a successful OAuth dance" do
        before do
          get '/hi'
          follow_successful_oauth!
        end

        it "redirects to the original request's path, exposing the email and the user but not the token" do
          assert_redirected_to_path('/hi')
          follow_redirect!

          assert_equal %w{ allow_tracking email id oauth_token}, last_request.env['bouncer.user'].keys.sort
          assert last_request.env['bouncer.email']
          assert last_request.env['bouncer.token'].nil?
          assert_equal 'hi', last_response.body
        end
      end
    end

    context "a login call via /auth/login with a 'return_to' param" do
      before do
        @return_to = 'http://google.com'
        get '/auth/login', 'return_to' => @return_to
      end

      it "redirects to /auth/heroku and after a successful authentication comes back to the given 'return_to'" do
        follow_successful_oauth!
        assert_equal @return_to, last_response.location
      end
    end

    context "a failed OAuth dance" do
      before do
        get '/auth/failure'
      end

      it "deletes the session and redirects to the root path" do
        assert_redirected_to_path('/')
      end
    end

    context "a SSO-style logout" do
      before do
        get '/auth/sso-logout'
      end

      it "redirects to the authentication endpoint's /logout path" do
        assert_equal "#{ENV['HEROKU_AUTH_URL']}/logout", last_response.location
      end
    end

    context "a regular logout" do
      before do
        get '/auth/logout'
      end

      it "redirects to the root path" do
        assert_redirected_to_path('/')
      end
    end
  end
end