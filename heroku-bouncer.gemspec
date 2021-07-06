Gem::Specification.new do |s|
  s.name = "heroku-bouncer"
  s.version = "0.8.0"

  s.authors = ["Jonathan Dance"]
  s.email = ["jd@heroku.com"]
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
  s.required_ruby_version = ">= 2.2"

  s.add_runtime_dependency("omniauth-heroku", "~> 0.1")
  s.add_runtime_dependency("sinatra", ">= 1.0", "< 3")
  s.add_runtime_dependency("faraday", ">= 0.8", "< 2")
  s.add_runtime_dependency("rack", ">= 1.0", "< 3")

  s.add_development_dependency("rake", "~> 10.0")
  s.add_development_dependency("minitest", "~> 5.0")
  s.add_development_dependency("minitest-spec-context", "~> 0.0")
  s.add_development_dependency("rack-test", "~> 1.1")
  s.add_development_dependency("mocha", "~> 1.1")
  s.add_development_dependency("delorean", "~> 2.1")
end
