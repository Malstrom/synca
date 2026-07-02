# frozen_string_literal: true

class PreferenceProfile < ApplicationRecord
  belongs_to :user

  enum :travel_style, { homebody: 0, balanced: 1, explorer: 2 }
end
