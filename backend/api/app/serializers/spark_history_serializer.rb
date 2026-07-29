# frozen_string_literal: true

# Row shape for `GET /sparks` — the Dashboard's "YOUR SPARKS" history list.
# Deliberately not SparkSerializer: that one carries session_code/qr_token
# (join credentials, useless once joined) and omits compatibility_score,
# which is the whole point of a history row.
class SparkHistorySerializer
  include Alba::Resource

  attributes :id,
             :status,
             :compatibility_score,
             :started_at,
             :completed_at
end
