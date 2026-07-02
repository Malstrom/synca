# frozen_string_literal: true

class SparkRewardSerializer
  include Alba::Resource

  attributes :id,
             :reward_type,
             :status,
             :valid_until
end
