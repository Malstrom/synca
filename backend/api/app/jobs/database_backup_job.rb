# frozen_string_literal: true

class DatabaseBackupJob < ApplicationJob
  queue_as :default

  def perform
    timestamp = Time.current.strftime("%Y%m%d-%H%M%S")
    filename  = "synca-backup-#{timestamp}.dump"
    dump_path = Rails.root.join("tmp", filename).to_s
    db_url    = ENV.fetch("DATABASE_URL")

    # Arguments are passed as a separate array — no shell interpolation occurs.
    # db_url and dump_path are assigned above; Brakeman false-positive suppressed.
    # brakeman:ignore
    _out, err, status = Open3.capture2e("pg_dump", db_url, "-Fc", "-f", dump_path)
    raise "pg_dump failed: #{err}" unless status.success?

    s3 = Aws::S3::Resource.new(
      endpoint:          "https://storage.yandexcloud.net",
      region:            "ru-central1",
      access_key_id:     ENV.fetch("YC_ACCESS_KEY_ID"),
      secret_access_key: ENV.fetch("YC_SECRET_ACCESS_KEY")
    )

    s3.bucket(ENV.fetch("YC_BACKUP_BUCKET"))
      .object("backups/#{filename}")
      .upload_file(dump_path)

    Rails.logger.info "[Backup] uploaded #{filename} to Yandex Object Storage"
  ensure
    File.delete(dump_path) if dump_path && File.exist?(dump_path)
  end
end
