# encoding: utf-8
require 'rubygems'
require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks

require 'cucumber/rake/task'

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = ""
  # t.cucumber_opts = "--format Cucumber::Pro --out cucumber-pro.log" if ENV['CUCUMBER_PRO_TOKEN']
  t.cucumber_opts << "--format pretty"
end

Cucumber::Rake::Task.new(:cucumber_wip) do |t|
  t.cucumber_opts = "-p wip"
end

require 'rspec/core/rake_task'
desc "Run RSpec"
RSpec::Core::RakeTask.new do |spec|
  spec.rspec_opts = ['--color', '--format documentation']
end

namespace :travis do
  desc 'Lint travis.yml'
  task :lint do
    begin
      require 'travis/yaml'

      puts 'Linting .travis.yml ... No output is good!'
      Travis::Yaml.parse! File.read('.travis.yml')
    rescue LoadError
      $stderr.puts 'You ruby is not supported for linting the .travis.yml'
    end
  end
end

if RUBY_VERSION < '1.9.3'
  begin
    require 'rubocop/rake_task'
    RuboCop::RakeTask.new
  rescue LoadError
    desc 'Stub task to make rake happy'
    task(:rubocop) {}
  end
else
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end

desc "Run tests, both RSpec and Cucumber"
task :test => [ 'travis:lint', :rubocop, :spec, :cucumber, :cucumber_wip]

task :default => :test
