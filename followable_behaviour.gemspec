# frozen_string_literal: true

require_relative "lib/followable_behaviour/version"

Gem::Specification.new do |spec|
  spec.name = "followable_behaviour"
  spec.version = FollowableBehaviour::VERSION
  spec.authors = ["Jean-Baptiste Francois"]
  spec.email = ["jbpfran@studiosjb.com"]

  spec.summary = "Seguidores polimórficos para Rails, con bloqueo e índices pensados para consultar por los dos lados."
  spec.description = "Fork de acts_as_follower mantenido para Ruby 3.2+ y Rails 7.1/8. " \
                     "Un registro sigue a otro mediante Follow, con bloqueo y alcances que no cargan filas de más."
  spec.homepage = "https://github.com/pollinoco/followable"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/pollinoco/followable"
  spec.metadata["changelog_uri"] = "https://github.com/pollinoco/followable/blob/main/CHANGELOG"
  spec.license = "MIT"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib,sig}/**/*", "CHANGELOG", "LICENSE", "README.md"].select { |path| File.file?(path) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.1", "< 9"
end
