# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Retry on transient DB lock errors.
  # polynomially_longer: 3s → 18s → 83s → 262s → 643s
  retry_on ActiveRecord::Deadlocked,        wait: :polynomially_longer, attempts: 5
  retry_on ActiveRecord::LockWaitTimeout,   wait: :polynomially_longer, attempts: 5

  # Discard jobs whose AR record was deleted between enqueue and execution.
  discard_on ActiveJob::DeserializationError
end
