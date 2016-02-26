# json parsers, all the way down
Heroku::Bouncer::JsonParserError = Class.new(RuntimeError)

Heroku::Bouncer::JsonParser = begin
  require 'oj'
  lambda { |json| Oj.load(json, :mode => :strict) rescue raise ::Heroku::Bouncer::JsonParserError }
rescue LoadError
  begin
    require 'yajl'
    lambda { |json| Yajl::Parser.parse(json) rescue raise ::Heroku::Bouncer::JsonParserError }
  rescue LoadError
    begin
      require 'multi_json'
      lambda { |json| MultiJson.decode(json) rescue raise ::Heroku::Bouncer::JsonParserError }
    rescue LoadError
      require 'json'
      lambda { |json| JSON.parse(json) rescue raise ::Heroku::Bouncer::JsonParserError }
    end
  end
end
