# Fix problems caused because tests all run in a single transaction.

# The single transaction means that after_commit callback never happens in tests.  Each of these method definitions
# overwrites the method in the after_commit plugin that stores the callback for after the commit.  In each case here
# we simply call the callback rather than waiting for a commit that will never come.

module AfterCommit::TestBypass
  def self.included(klass)
    klass.class_eval do
      %w(create update save destroy).each do |action|
        remove_method "add_committed_record_on_#{action}"
      end
    end
  end

  def add_committed_record_on_create
    callback :after_commit
    callback :after_commit_on_create
  end

  def add_committed_record_on_update
    callback :after_commit
    callback :after_commit_on_update
  end

  def add_committed_record_on_save
    callback :after_commit_on_save
  end

  def add_committed_record_on_destroy
    callback :after_commit
    callback :after_commit_on_destroy
  end
end
