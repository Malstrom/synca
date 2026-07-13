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
      raise StandardError, "record gone"
    rescue
      raise ActiveJob::DeserializationError
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

  test "retries on Deadlocked" do
    assert_enqueued_with(job: AlwaysDeadlockJob) do
      AlwaysDeadlockJob.perform_now
    end
  end

  test "retries on LockWaitTimeout" do
    assert_enqueued_with(job: AlwaysLockTimeoutJob) do
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
