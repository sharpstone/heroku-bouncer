require_relative "test_helper"

describe Heroku::Bouncer do
  include Rack::Test::Methods

  context "allow_if block" do
    before do
      @app = app_with_bouncer do
        {
          allow_if: lambda { |email| email.end_with? "@initech.com" }
        }
      end
    end

    context "after a successful OAuth dance returning an allowed email" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'milton@initech.com'})
      end

      it "gives access to the app" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert_equal 'hi', last_response.body
      end
    end

    context "after a successful OAuth dance  with an invalid email" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'joe@a.com'})
      end

      it "redirects to 'https://www.heroku.com'" do
        assert_equal 'https://www.heroku.com', last_response.location
      end
    end
  end

  context "allow_if uses redirect_url" do
    before do
      @app = app_with_bouncer do
        {
          allow_if: lambda { |email| email.end_with? "@initech.com" },
          redirect_url: 'https://whoopsie.heroku.com'
        }
      end
    end

    context "after a successful OAuth dance returning an allowed email" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'milton@initech.com'})
      end

      it "gives access to the app" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert_equal 'hi', last_response.body
      end
    end

    context "after a successful OAuth dance returning an invalid email" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'root@nic.ca'})
      end

      it "redirects to the given URL" do
        assert_equal 'https://whoopsie.heroku.com', last_response.location
      end
    end
  end

  context "no allow_auth lets everyone in" do
    before do
      @app = app_with_bouncer do
        {
          expose_user: false
        }
      end
    end

    context "after a successful OAuth dance, allows anyone in" do
      before do
        get '/hi'
      end

      ['joe@a.com', 'milton@initech.com'].each do |email|
        it "gives access to the app" do
          follow_successful_oauth!({'email' => email})

          assert_redirected_to_path('/hi')
          follow_redirect!

          assert_equal 'hi', last_response.body
        end
      end
    end
  end

  context "allow_if_user block" do
    before do
      @app = app_with_bouncer do
        {
          allow_if_user: lambda { |user| user['email'].end_with? "@initech.com" }
        }
      end
    end

    context "after a successful OAuth dance returning an allowed email" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'milton@initech.com'})
      end

      it "gives access to the app" do
        assert_redirected_to_path('/hi')
        follow_redirect!

        assert_equal 'hi', last_response.body
      end
    end

    context "after a successful OAuth dance  with an invalid email" do
      before do
        get '/hi'
        follow_successful_oauth!({'email' => 'joe@a.com'})
      end

      it "redirects to 'https://www.heroku.com'" do
        assert_equal 'https://www.heroku.com', last_response.location
      end
    end
  end
end
