# frozen_string_literal: true

require "bundler/gem_tasks"
task default: :test

require 'rake'
require 'rake/testtask'

desc 'Test the followable_behaviour gem.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end