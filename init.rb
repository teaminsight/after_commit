require 'after_commit'

# enable TestBypass by default in RAILS_ENV == 'test'
ActiveRecord::Base.class_eval do 
  include AfterCommit::TestBypass if RAILS_ENV == 'test'
end