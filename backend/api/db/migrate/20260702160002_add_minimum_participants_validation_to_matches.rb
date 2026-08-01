# frozen_string_literal: true

class AddMinimumParticipantsValidationToMatches < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE matches
          ADD CONSTRAINT check_minimum_participants
          CHECK (
            (SELECT COUNT(*) FROM match_participants WHERE match_id = id) >= 2
          )
        SQL
      end

      dir.down do
        execute <<~SQL
          ALTER TABLE matches
          DROP CONSTRAINT check_minimum_participants
        SQL
      end
    end
  end
end
