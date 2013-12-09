Gem::Specification.new do |s|
  s.name = %q{heroku-bouncer}
  s.version = "0.4.0.pre3"

  s.authors = ["Jonathan Dance"]
  s.email = ["jd@heroku.com"]
  s.homepage = "https://github.com/heroku/heroku-bouncer"
  s.description = "ID please."
  s.summary = "Rapidly add Heroku OAuth to your Ruby app."
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = Dir.glob("{lib,spec}/**/*").concat([
    "README.md",
    "Gemfile",
    "Gemfile.lock",
    "Rakefile",
  ])
  s.require_paths = ["lib"]
  s.test_files = Dir.glob("spec/**/*").concat([
    "Gemfile",
    "Gemfile.lock",
    "Rakefile",
  ])
  s.license = 'MIT'

  s.add_runtime_dependency("omniauth-heroku", [">= 0.1.0"])
  s.add_runtime_dependency("sinatra", ["~> 1.0"])
  s.add_runtime_dependency("faraday", ["~> 0.8"])
  s.add_runtime_dependency("rack", ["~> 1.0"])

  s.add_development_dependency("rake")
  s.add_development_dependency("minitest", "~> 5.0")
  s.add_development_dependency("minitest-spec-context")
  s.add_development_dependency("rack-test")
  s.add_development_dependency("mocha")
end
