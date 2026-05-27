# frozen_string_literal: true

require "zlib"

class DatabaseBackupJob < ApplicationJob
  queue_as :default

  TABLES = %w[
    users profiles health_summaries preference_profiles
    matches match_participants spark_sessions spark_rewards
  ].freeze

  def perform
    timestamp = Time.current.strftime("%Y%m%d-%H%M%S")
    filename  = "synca-backup-#{timestamp}.csv.gz"
    tmp_path  = Rails.root.join("tmp", filename).to_s

    conn = ActiveRecord::Base.connection.raw_connection

    Zlib::GzipWriter.open(tmp_path) do |gz|
      TABLES.each do |table|
        gz.write("-- TABLE: #{table}\n")
        conn.copy_data("COPY #{table} TO STDOUT WITH (FORMAT csv, HEADER true)") do
          while (row = conn.get_copy_data)
            gz.write(row)
          end
        end
        gz.write("\n")
      end
    end

    upload_to_s3(filename, tmp_path)
    Rails.logger.info "[Backup] uploaded #{filename} to Yandex Object Storage"
  ensure
    File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
  end

  private

  def upload_to_s3(filename, path)
    Aws::S3::Resource.new(
      endpoint:          "https://storage.yandexcloud.net",
      region:            "ru-central1",
      access_key_id:     ENV.fetch("YC_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("YC_SECRET_ACCESS_KEY")
    )
    .bucket(ENV.fetch("YC_BACKUP_BUCKET"))
    .object("backups/#{filename}")
    .upload_file(path)
  end
end
