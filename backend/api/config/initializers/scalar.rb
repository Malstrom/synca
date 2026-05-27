# frozen_string_literal: true

return unless Rails.env.development?

Scalar.setup do |config|
  config.page_title    = "Synca API"

  # Legge direttamente il tuo openapi.yaml già esistente in docs/api/
  config.configuration = {
    content: File.read(Rails.root.join("../../docs/api/openapi.yaml")),
    theme:   "kepler",       # dark, minimal, kepler, saturn, solarized, bluePlanet...
    authentication: {
      preferredSecurityScheme: "bearerAuth"
    }
  }
end