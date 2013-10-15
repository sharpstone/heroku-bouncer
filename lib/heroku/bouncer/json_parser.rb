# json parsers, all the way down
Heroku::Bouncer::JsonParser = begin
  require 'oj'
  lambda { |json| Oj.load(json, :mode => :strict) }
rescue LoadError
  begin
    require 'yajl'
    lambda { |json| Yajl::Parser.parse(json) }
  rescue LoadError
    begin
      require 'multi_json'
      lambda { |json| MultiJson.decode(json) }
    rescue LoadError
      require 'json'
      lambda { |json| JSON.parse(json) }
    end
  end
end
