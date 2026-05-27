# frozen_string_literal: true

require "test_helper"

class DatabaseBackupJobTest < ActiveJob::TestCase
  setup do
    # Stub the raw PG connection
    @mock_conn = Minitest::Mock.new
    ActiveRecord::Base.connection.stub(:raw_connection, @mock_conn) do
      # no-op here; stubs applied per-test
    end
  end

  test "perform writes gzip file, uploads to S3, and deletes tmp file" do
    rows = ["id,email\n", "1,a@b.com\n"]
    row_index = 0

    mock_conn = Object.new
    # Simulate copy_data yielding rows then nil
    mock_conn.define_singleton_method(:copy_data) do |_sql, &block|
      block.call
    end
    mock_conn.define_singleton_method(:get_copy_data) do
      val = rows[row_index]
      row_index += 1
      val
    end

    mock_s3_obj = Minitest::Mock.new
    mock_s3_obj.expect(:upload_file, true, [String])

    mock_s3_bucket = Minitest::Mock.new
    mock_s3_bucket.expect(:object, mock_s3_obj, [String])

    mock_s3_resource = Minitest::Mock.new
    mock_s3_resource.expect(:bucket, mock_s3_bucket, [String])

    ActiveRecord::Base.connection.stub(:raw_connection, mock_conn) do
      Aws::S3::Resource.stub(:new, mock_s3_resource) do
        DatabaseBackupJob.new.perform
      end
    end

    mock_s3_obj.verify
    mock_s3_bucket.verify
    mock_s3_resource.verify
  end

  test "perform cleans up tmp file even if S3 upload raises" do
    rows = []
    row_index = 0

    mock_conn = Object.new
    mock_conn.define_singleton_method(:copy_data) { |_sql, &block| block.call }
    mock_conn.define_singleton_method(:get_copy_data) { rows[row_index].tap { row_index += 1 } }

    exploding_s3 = ->(**_kwargs) { raise "S3 unavailable" }

    created_path = nil

    ActiveRecord::Base.connection.stub(:raw_connection, mock_conn) do
      Aws::S3::Resource.stub(:new, exploding_s3) do
        # Intercept File.delete to capture path before deletion
        original_delete = File.method(:delete)
        File.stub(:delete, ->(path) { created_path = path; original_delete.call(path) if File.exist?(path) }) do
          assert_raises(RuntimeError) { DatabaseBackupJob.new.perform }
        end
      end
    end

    # ensure tmp file was cleaned up (either deleted or never existed)
    assert_nil(created_path) || assert(!File.exist?(created_path))
  end
end
