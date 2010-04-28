require 'test_helper'

class MockRecord < ActiveRecord::Base
  attr_accessor :before_commit_on_create_called
  attr_accessor :before_commit_on_update_called
  attr_accessor :before_commit_on_destroy_called
  attr_accessor :before_commit_called
  attr_accessor :after_commit_on_create_called
  attr_accessor :after_commit_on_update_called
  attr_accessor :after_commit_on_destroy_called
  attr_accessor :after_commit_called
  

  before_commit_on_create :do_before_create
  def do_before_create
    self.before_commit_on_create_called = true
  end

  before_commit_on_update :do_before_update
  def do_before_update
    self.before_commit_on_update_called = true
  end

  before_commit_on_destroy :do_before_destroy
  def do_before_destroy
    self.before_commit_on_destroy_called = true
  end

  before_commit :do_before_commit
  def do_before_commit
    self.before_commit_called = true
  end

  after_commit_on_create :do_after_create
  def do_after_create
    self.after_commit_on_create_called = true
  end

  after_commit_on_update :do_after_update
  def do_after_update
    self.after_commit_on_update_called = true
  end

  after_commit_on_destroy :do_after_destroy
  def do_after_destroy
    self.after_commit_on_destroy_called = true
  end

  after_commit :do_after_commit
  def do_after_commit
    self.after_commit_called = true
  end
end

class CountingRecord < ActiveRecord::Base
  attr_accessor :after_commit_on_create_called
  cattr_accessor :counter
  @@counter=0
  
  after_commit_on_create :do_after_create
  def do_after_create
    @@counter+=1
  end
end

class Foo < ActiveRecord::Base
  attr_reader :creating
  
  after_commit :create_bar
  
  private
  
  def create_bar
    @creating ||= 0
    @creating += 1
    
    raise Exception, 'looping' if @creating > 1
    Bar.create
  end
end

class Bar < ActiveRecord::Base
  #
end

class UnsavableRecord < ActiveRecord::Base
  attr_accessor :after_commit_called

  set_table_name 'mock_records'

  protected

  def after_initialize
    self.after_commit_called = false
  end

  def after_save
    raise
  end

  after_commit :after_commit

  def after_commit
    self.after_commit_called = true
  end
end

class TrackCountRecord < ActiveRecord::Base
  attr_accessor :total_count

  set_table_name 'mock_records'

  protected

  after_commit :update_counts
  after_rollback :update_counts

  def update_counts
    all_records =
      AfterCommit.records(connection) +
      AfterCommit.created_records(connection) +
      AfterCommit.updated_records(connection) +
      AfterCommit.destroyed_records(connection)
    all_records.uniq!
    self.total_count = all_records.size
  end
end

class AfterCommitTest < Test::Unit::TestCase
  def test_before_commit_on_create_is_called
    assert_equal true, MockRecord.create!.before_commit_on_create_called
  end
  
  def test_before_commit_on_update_is_called
    record = MockRecord.create!
    record.save
    assert_equal true, record.before_commit_on_update_called
  end
  
  def test_before_commit_on_destroy_is_called
    assert_equal true, MockRecord.create!.destroy.before_commit_on_destroy_called
  end
  
  def test_after_commit_on_create_is_called
    assert_equal true, MockRecord.create!.after_commit_on_create_called
  end
  
  def test_after_commit_on_update_is_called
    record = MockRecord.create!
    record.save
    assert_equal true, record.after_commit_on_update_called
  end
  
  def test_after_commit_on_destroy_is_called
    record = MockRecord.create!
    
    # reset states set by create!
    record.before_commit_called = false 
    record.after_commit_called = false
    record.destroy
    
    assert_equal true, record.after_commit_on_destroy_called
    assert_equal false, record.after_commit_called
    assert_equal false, record.before_commit_called
  end
  
  def test_after_commit_does_not_trigger_when_transaction_rolls_back
    record = UnsavableRecord.new
    begin; record.save; rescue; end
  
    assert_equal false, record.after_commit_called
  end

  def test_after_commit_does_not_trigger_when_unrelated_transaction_commits
    begin
      CountingRecord.transaction do
        CountingRecord.create!
        raise "fail"
      end
    rescue
    end
    assert_equal 0, CountingRecord.counter
    CountingRecord.create!
    assert_equal 1, CountingRecord.counter
  end
  
  def test_two_transactions_are_separate
    Bar.delete_all
    foo = Foo.create
    
    assert_equal 1, foo.creating
  end
  
  def test_records_with_callbacks_are_tracked
    record = nil
    MockRecord.transaction do
      record = TrackCountRecord.create!
      5.times.each { MockRecord.create! }
    end
    assert_equal 6, record.total_count
  end
  
  def test_records_without_callbacks_are_not_tracked
    record = nil
    MockRecord.transaction do
      record = TrackCountRecord.create!
      5.times.each { Bar.create! }
    end
    assert_equal 1, record.total_count
  end

  TestError = Class.new(StandardError)

  def test_exceptions_in_before_commit_on_create_are_not_swallowed
    record = MockRecord.new
    def record.do_before_create
      raise TestError, 'catch me!'
    end
    assert_raises(TestError){record.save!}
  end

  def test_exceptions_in_after_commit_on_create_are_not_swallowed
    record = MockRecord.new
    def record.do_after_create
      raise TestError, 'catch me!'
    end
    assert_raises(TestError){record.save!}
  end

  def test_exceptions_in_before_commit_on_update_are_not_swallowed
    record = MockRecord.create
    def record.do_before_update
      raise TestError, 'catch me!'
    end
    assert_raises(TestError){record.update_attributes({})}
  end

  def test_exceptions_in_after_commit_on_update_are_not_swallowed
    record = MockRecord.create
    def record.do_after_update
      raise TestError, 'catch me!'
    end
    assert_raises(TestError){record.update_attributes({})}
  end

  def test_exceptions_in_before_commit_on_destroy_are_not_swallowed
    record = MockRecord.create
    def record.do_before_destroy
      raise TestError, 'catch me!'
    end
    assert_raises(TestError){record.destroy}
  end

  def test_exceptions_in_after_commit_on_destroy_are_not_swallowed
    record = MockRecord.create
    def record.do_after_destroy
      raise TestError, 'catch me!'
    end
    assert_raises(TestError){record.destroy}
  end

  def test_transactions_in_hooks_do_not_cause_spurious_rollbacks
    record = MockRecord.create
    def record.do_after_destroy
      MockRecord.transaction{}
      raise TestError, 'catch me!'
    end
    assert_raises(TestError){record.destroy}
  end
end
