# define Heroku and Heroku::Bouncer
module Heroku
  class Bouncer
    def self.new(*args)
      Heroku::Bouncer::Builder.new(*args)
    end
  end
end

require 'heroku/bouncer/builder'
