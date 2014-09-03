require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "herokai_only: true" do
    before do
      @app = app_with_bouncer do
        {
          herokai_only: true
        }
      end
    end

    context "after a successful OAuth dance returning a Herokai" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'joe@heroku.com'})
      end

      it "gives access to the app" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert_equal 'hi', last_response.body
      end
    end

    context "after a successful OAuth dance returning a non-Herokai" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'joe@a.com'})
      end

      it "redirects to 'https://www.heroku.com'" do
        assert_equal 'https://www.heroku.com', last_response.location
      end
    end
  end

  context "herokai_only uses redirect_url" do
    before do
      @app = app_with_bouncer do
        {
          herokai_only: true,
          redirect_url: 'https://whoopsie.heroku.com'
        }
      end
    end

    context "after a successful OAuth dance returning a Herokai" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'joe@heroku.com'})
      end

      it "gives access to the app" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert_equal 'hi', last_response.body
      end
    end

    context "after a successful OAuth dance returning a non-Herokai" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'root@nic.ca'})
      end

      it "redirects to the given URL" do
        assert_equal 'https://whoopsie.heroku.com', last_response.location
      end
    end
  end

  context "herokai_only: <URL>" do
    before do
      @app = app_with_bouncer do
        {
          herokai_only: 'https://bummer.heroku.com'
        }
      end
    end

    context "after a successful OAuth dance returning a Herokai" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'joe@heroku.com'})
      end

      it "gives access to the app" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert_equal 'hi', last_response.body
      end
    end

    context "after a successful OAuth dance returning a non-Herokai" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'joe@a.com'})
      end

      it "redirects to the given URL" do
        assert_equal 'https://bummer.heroku.com', last_response.location
      end
    end
  end



  context "herokai_only: false" do
    before do
      @app = app_with_bouncer do
        {
          expose_user: false
        }
      end
    end

    context "after a successful OAuth dance, wether it returns a Herokai or not" do
      before do
        get '/hi'
      end

      ['joe@a.com', 'joe@heroku.com'].each do |email|
        it "gives access to the app" do
          follow_successful_oauth!({'email' => email})

          assert_redirected_to_path('/hi')
          follow_redirect!

          assert_equal 'hi', last_response.body
        end
      end
    end
  end
end
