# frozen_string_literal: true

require_relative "lib/followable_behaviour/version"

Gem::Specification.new do |spec|
  spec.name = "followable_behaviour"
  spec.version = FollowableBehaviour::VERSION
  spec.authors = ["Jean-Baptiste Francois"]
  spec.email = ["jbpfran@studiosjb.com"]

  spec.summary = "Updated fork of the unmaintained gem acts_as_followers."
  spec.description = "Updated fork of the unmaintained gem acts_as_followers. It was tested with Ruby 3.1.2 and Rails 7"
  spec.homepage = "https://gitlab.com/jbpfran/followable-behaviour"
  spec.required_ruby_version = ">= 2.6.0"

  #spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://gitlab.com/jbpfran/followable-behaviour"
  spec.metadata["changelog_uri"] = "https://gitlab.com/jbpfran/followable-behaviour/-/blob/main/CHANGELOG"
  spec.license = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_dependency 'activerecord', "~> 8.0"

  spec.add_development_dependency "sqlite3", "~> 1.5"
  spec.add_development_dependency "shoulda_create"
  spec.add_development_dependency "shoulda"
  spec.add_development_dependency "factory_bot", "~> 6.2"
  spec.add_development_dependency "rails", "~> 8.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
