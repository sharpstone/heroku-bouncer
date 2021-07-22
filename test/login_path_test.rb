require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "login_path" do
    it "redirects unauthenticated requests to the default login path" do
      @app = app_with_bouncer

      get "/hi"
      assert 302, last_response.status
      assert_equal "http://#{app_host}/auth/login", last_response.location
    end

    context "with a custom login path" do
      before do
        @app = app_with_bouncer do
          {login_path: "/custom/login"}
        end

        app.get("/custom/login") do
          <<-HTML
            <!DOCTYPE html>
            <html lang="en">
              <body>
                <form method="post" action="/auth/heroku">
                  <input type="hidden" name="authenticity_token" value="#{request.env["rack.session"]["csrf"]}">
                <button type="submit">Do it!</button>
              </body>
            </html>
          HTML
        end
      end

      it "redirects unauthenticated requests to the custom path" do
        get "/hi"
        assert 302, last_response.status
        assert_equal "http://#{app_host}/custom/login", last_response.location
      end

      it "completes the OAuth dance" do
        get "/hi"
        follow_redirect!
        submit_successful_oauth!

        assert_redirected_to_path("/hi")
      end
    end
  end
end
