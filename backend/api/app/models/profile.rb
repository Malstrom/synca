# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user

  enum :gender, { male: "male", female: "female", non_binary: "non_binary", other: "other" },
       prefix: false

  scope :verified, -> { where(spark_verified: true) }
end
