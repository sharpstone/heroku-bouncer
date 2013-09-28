Heroku::Bouncer::JsonParser = begin
  require 'oj'
  lambda { |json| Oj.load(json, :mode => :strict) }
rescue LoadError
  require 'yajl'
  lambda { |json| Yajl::Parser.parse(json) }
rescue LoadError
  require 'multi_json'
  lambda { |json| MultiJson.decode(json) }
rescue LoadError
  require 'json'
  lambda { |json| JSON.parse(json) }
end
