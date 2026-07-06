# frozen_string_literal: true

class PreferenceProfile < ApplicationRecord
  belongs_to :user

  enum :temperature_preference, { cool: 0, warm: 1, no_preference: 2 }
  enum :movement_preference, { very_little: 0, moderate: 1, a_lot: 2, as_much_as_possible: 3 }
  enum :self_chronotype, { morning: 0, night: 1, depends: 2 }
end
