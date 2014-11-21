# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
  s.name = 'delayed_job_rake_daemon'
  s.summary = 'Workaround for a nasty gem interaction bug in the standard delayed_job worker script'
  s.description = 'Workaround for a nasty gem interaction bug in the standard delayed_job worker script'
  s.email = 'steve@stevemadere.com'
  s.homepage = 'https://github.com/stevemadere/delayed_job_rake_daemon'
  s.license = 'MIT'
  s.version = '0.0.1'
  s.authors = 'Steve Madere'
  s.files = Dir.glob('{lib}/**/*')
  s.executables = ['delayed_job_rake_daemon']
  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.2'
end
