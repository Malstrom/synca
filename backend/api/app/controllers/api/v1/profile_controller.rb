# frozen_string_literal: true

module Api
  module V1
    class ProfileController < ApplicationController
      # PUT /api/v1/me/profile
      def update
        profile = current_user.profile || current_user.build_profile

        unless profile.update(profile_params)
          return render_validation_errors(profile)
        end

        render_success({ profile: profile_payload(profile) })
      end

      private

        def profile_params
          params.require(:profile).permit(
            :display_name,
            :bio,
            :city,
            :birth_date,
            :gender,
            :photo_url_main,
            photo_urls: []
          )
        end

        def profile_payload(profile)
          {
            display_name:   profile.display_name,
            bio:            profile.bio,
            city:           profile.city,
            birth_date:     profile.birth_date,
            gender:         profile.gender,
            photo_url_main: profile.photo_url_main,
            photo_urls:     profile.photo_urls,
            trust_score:    profile.trust_score,
            spark_verified: profile.spark_verified
          }
        end
    end
  end
end
