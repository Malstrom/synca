# frozen_string_literal: true

require "test_helper"

class DatabaseBackupJobTest < ActiveJob::TestCase
  test "perform writes gzip file, uploads to S3, and deletes tmp file" do
    rows = [ "id,email\n", "1,a@b.com\n", nil ]
    row_index = 0

    mock_conn = Object.new
    mock_conn.define_singleton_method(:copy_data) { |_sql, &block| block.call }
    mock_conn.define_singleton_method(:get_copy_data) { rows[(row_index += 1) - 1] }

    mock_s3_obj    = Minitest::Mock.new
    mock_s3_bucket = Minitest::Mock.new
    mock_s3_res    = Minitest::Mock.new

    mock_s3_obj.expect(:upload_file, true, [ String ])
    mock_s3_bucket.expect(:object, mock_s3_obj, [ String ])
    mock_s3_res.expect(:bucket, mock_s3_bucket, [ String ])

    ActiveRecord::Base.connection.stub(:raw_connection, mock_conn) do
      Aws::S3::Resource.stub(:new, mock_s3_res) do
        DatabaseBackupJob.new.perform
      end
    end

    mock_s3_obj.verify
    mock_s3_bucket.verify
    mock_s3_res.verify
  end

  test "perform cleans up tmp file even if S3 upload raises" do
    rows = [ nil ]
    row_index = 0

    mock_conn = Object.new
    mock_conn.define_singleton_method(:copy_data) { |_sql, &block| block.call }
    mock_conn.define_singleton_method(:get_copy_data) { rows[(row_index += 1) - 1] }

    exploding_s3 = ->(**_kwargs) { raise RuntimeError, "S3 unavailable" }

    deleted_paths = []
    stub_delete = ->(path) { deleted_paths << path }

    ActiveRecord::Base.connection.stub(:raw_connection, mock_conn) do
      Aws::S3::Resource.stub(:new, exploding_s3) do
        File.stub(:exist?, true) do
          File.stub(:delete, stub_delete) do
            assert_raises(RuntimeError) { DatabaseBackupJob.new.perform }
          end
        end
      end
    end

    assert_equal 1, deleted_paths.size, "expected tmp file to be deleted in ensure"
    assert_match(/synca-backup-.+\.csv\.gz/, deleted_paths.first)
  end
end
