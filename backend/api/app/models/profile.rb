# frozen_string_literal: true

class Profile < ApplicationRecord
  belongs_to :user

  enum :gender, { male: "male", female: "female", non_binary: "non_binary", other: "other" },
       prefix: false

  validates :display_name, presence: true, length: { maximum: 50 }
  validates :bio,          length: { maximum: 300 }, allow_blank: true
  validates :trust_score,  numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :photo_urls,   length: { maximum: 6 }, allow_blank: true
end
