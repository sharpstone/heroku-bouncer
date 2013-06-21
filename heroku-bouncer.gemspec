Gem::Specification.new do |s|
  s.name = %q{heroku-bouncer}
  s.version = "0.2.1"

  s.authors = ["Jonathan Dance"]
  s.email = ["jd@heroku.com"]
  s.homepage = "https://github.com/heroku/heroku-bouncer"
  s.description = "ID please."
  s.summary = "Requires Heroku OAuth on all requests."
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

  s.add_runtime_dependency("omniauth-heroku", [">= 0.1.0"])
  s.add_runtime_dependency("sinatra", ["~> 1.0"])
  s.add_runtime_dependency("faraday", ["~> 0.8"])
  s.add_runtime_dependency("multi_json", ["~> 1.0"])
  s.add_runtime_dependency("encrypted_cookie", ["~> 0.0.4"])
end
