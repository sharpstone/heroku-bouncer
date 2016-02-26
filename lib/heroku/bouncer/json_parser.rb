# json parsers, all the way down
Heroku::Bouncer::JsonParserError = Class.new(RuntimeError)

Heroku::Bouncer::JsonParser = begin

  require 'oj'

  lambda do |json|
    begin
      Oj.load(json, :mode => :strict)
    rescue
      raise ::Heroku::Bouncer::JsonParserError
    end
  end

rescue LoadError

  begin

    require 'yajl'
    lambda do |json|
      begin
        Yajl::Parser.parse(json)
      rescue
        raise ::Heroku::Bouncer::JsonParserError
      end
    end

  rescue LoadError

    begin

      require 'multi_json'
      lambda do |json|
        begin
          MultiJson.decode(json)
        rescue
          raise ::Heroku::Bouncer::JsonParserError
        end
      end

    rescue LoadError

      require 'json'
      lambda do |json|
        begin
          JSON.parse(json)
        rescue
          raise ::Heroku::Bouncer::JsonParserError
        end
      end

    end
  end
end
