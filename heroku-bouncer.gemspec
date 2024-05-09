Gem::Specification.new do |s|
  s.name = "heroku-bouncer"
  s.version = "0.9.0"

  s.authors = ["Jonathan Dance"]
  s.email = ["jd@wuputah.com"]
  s.homepage = "https://github.com/heroku/heroku-bouncer"
  s.description = "ID please."
  s.summary = "Rapidly add Heroku OAuth to your Ruby app."
  s.extra_rdoc_files = [
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
  ]
  s.files = Dir.glob("{lib,spec}/**/*").concat([
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "Gemfile",
    "Rakefile",
  ])
  s.require_paths = ["lib"]
  s.test_files = Dir.glob("spec/**/*").concat([
    "Gemfile",
    "Rakefile",
  ])
  s.license = "MIT"
  s.required_ruby_version = ">= 3.1"

  s.add_runtime_dependency("omniauth-heroku", [">= 0.1", "< 2"])
  s.add_runtime_dependency("sinatra", ">= 3.0", "< 4")
  s.add_runtime_dependency("faraday", ">= 0.8", "< 2")
  s.add_runtime_dependency("rack", ">= 2.0", "< 4")

  s.add_development_dependency("rake", ">= 12.3.3")
  s.add_development_dependency("minitest", "~> 5.0")
  s.add_development_dependency("minitest-spec-context", "~> 0.0")
  s.add_development_dependency("rack-test", "~> 1.1")
  s.add_development_dependency("mocha", "~> 2.2")
  # We need to allow older Nokogiri b/c newer versions require newer Rubies.
  # Consider bumping this when we drop older Ruby support.
  s.add_development_dependency("nokogiri", "~> 1.16.4")
  s.add_development_dependency("delorean", "~> 2.1")
end
