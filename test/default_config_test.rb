require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "the default configuration" do

    before do
      @app = app_with_bouncer
    end

    after do
      Delorean.back_to_the_present
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

        it "requires a new authentication when the session expires" do
          assert_redirected_to_path('/hi')
          follow_redirect!
          assert_equal 'hi', last_response.body

          # session expires
          Delorean.time_travel_to '1 year from now'

          # requires authentication
          get '/hi'
          assert 302, last_response.status
          assert_equal "http://#{app_host}/auth/heroku", last_response.location

          follow_successful_oauth!
          assert_redirected_to_path('/hi')
          follow_redirect!
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
      it "redirects to the authentication endpoint's /logout path" do
        get '/auth/sso-logout'
        assert_equal "#{ENV['HEROKU_AUTH_URL']}/logout", last_response.location
      end

      it "supports an optional `return_to` param to be used by the authentication endpoint's /logout path" do
        return_to = 'https://app.heroku.com'
        get "/auth/sso-logout?return_to=#{return_to}"
        assert_equal "#{ENV['HEROKU_AUTH_URL']}/logout?url=#{return_to}", last_response.location
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