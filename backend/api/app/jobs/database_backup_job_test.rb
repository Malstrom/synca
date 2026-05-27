# frozen_string_literal: true

# test/jobs/database_backup_job_test.rb
require "test_helper"

class DatabaseBackupJobTest < ActiveJob::TestCase
  test "job is enqueued" do
    assert_enqueued_with(job: DatabaseBackupJob) do
      DatabaseBackupJob.perform_later
    end
  end
end
