require_relative "lib/nucleus_core/version"

Gem::Specification.new do |spec|
  spec.name = "nucleus-core"
  spec.version = NucleusCore::VERSION
  spec.authors = ["dodgerogers"]
  spec.email = ["dodgerogers@hotmail.com"]
  spec.summary = "A Ruby business logic framework"
  spec.homepage = "https://github.com/dodgerogers/nucleus-core"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6"
  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/dodgerogers/nucleus-core/issues",
    "changelog_uri" => "https://github.com/dodgerogers/nucleus-core/releases",
    "source_code_uri" => "https://github.com/dodgerogers/nucleus-core",
    "homepage_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.glob(%w[LICENSE.txt README.md {exe,lib}/**/*]).reject { |f| File.directory?(f) }
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
