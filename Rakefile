# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

namespace :docs do
  desc "Reformat docs/**/*.md in place with pandoc (gfm, 72 columns)"
  task :fmt do
    FileList["docs/**/*.md"].each do |path|
      formatted = IO.popen(%w[pandoc -f gfm -t gfm-smart --columns=72], "r+") do |io|
        io.write File.read(path)
        io.close_write
        io.read
      end
      fail "pandoc failed on #{path}" unless $?.success?
      # pandoc writes "``` ruby"; conventional GFM is "```ruby"
      formatted = formatted.gsub(/^(\s*)``` (\S)/, '\1```\2')
      File.write(path, formatted)
      puts path
    end
  end
end

task :default => :spec
