class PreferenceProfile < ApplicationRecord
  belongs_to :user

  enum :travel_style, { homebody: 0, balanced: 1, explorer: 2 }

  validates :visual_embedding, presence: false  # optional in MVP
end
