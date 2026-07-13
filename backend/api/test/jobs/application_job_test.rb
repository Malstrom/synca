# frozen_string_literal: true

require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  class AlwaysDeadlockJob < ApplicationJob
    def perform
      raise ActiveRecord::Deadlocked, "deadlock detected"
    end
  end

  class AlwaysLockTimeoutJob < ApplicationJob
    def perform
      raise ActiveRecord::LockWaitTimeout, "lock wait timeout"
    end
  end

  class AlwaysDeserializationErrorJob < ApplicationJob
    def perform
      raise ActiveJob::DeserializationError.new(StandardError.new("record not found"))
    end
  end

  class SuccessJob < ApplicationJob
    cattr_accessor :performed, default: false

    def perform
      self.class.performed = true
    end
  end

  setup do
    SuccessJob.performed = false
  end

  test "retries on Deadlocked up to configured attempts" do
    assert_raises(ActiveRecord::Deadlocked) do
      AlwaysDeadlockJob.perform_now
    end
  end

  test "retries on LockWaitTimeout up to configured attempts" do
    assert_raises(ActiveRecord::LockWaitTimeout) do
      AlwaysLockTimeoutJob.perform_now
    end
  end

  test "discards on DeserializationError without raising" do
    assert_nothing_raised do
      AlwaysDeserializationErrorJob.perform_now
    end
  end

  test "executes normally when no exception" do
    SuccessJob.perform_now
    assert SuccessJob.performed
  end
end
