# frozen_string_literal: true

class ProfileSerializer
  include Alba::Resource

  attributes :display_name,
             :bio,
             :city,
             :birth_date,
             :gender,
             :photo_url_main,
             :photo_urls,
             :trust_score,
             :spark_verified
end
