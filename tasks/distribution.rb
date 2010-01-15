require 'rake/rdoctask'
require 'jeweler'

desc 'Generate documentation for the after_commit plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'AfterCommit'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

Jeweler::Tasks.new do |gem|
  gem.name = 'larsklevan-after_commit'
  gem.summary = 'after_commit callback for ActiveRecord'
  gem.description = %Q{
    A Ruby on Rails plugin to add an after_commit callback. This can be used to trigger methods only after the entire transaction is complete.
    Updated with savepoint support for unit testing.
  }
  gem.email = "tastybyte@gmail.com"
  gem.homepage = "http://github.com/larsklevan/after_commit"
  gem.authors = ["Nick Muerdter", "David Yip", "Pat Allan", "Lars Klevan"]
  
  gem.files = FileList[
    'lib/**/*.rb',
    'LICENSE',
    'rails/**/*.rb',
    'README'
  ]
  gem.test_files = FileList[
    'test/**/*.rb'
  ]
  
  gem.add_dependency 'activerecord'
  gem.add_development_dependency 'shoulda'
end
