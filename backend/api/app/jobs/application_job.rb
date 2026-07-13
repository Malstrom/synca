# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Retry on transient DB lock errors with exponential backoff.
  # Safe because all jobs must be idempotent.
  # Attempts value must match Settings.jobs.retry_attempts in config/settings/jobs.yml.
  retry_on ActiveRecord::Deadlocked,      wait: :polynomially_longer, attempts: 5
  retry_on ActiveRecord::LockWaitTimeout, wait: :polynomially_longer, attempts: 5

  # Discard jobs whose AR record was deleted between enqueue and execution.
  discard_on ActiveJob::DeserializationError
end
