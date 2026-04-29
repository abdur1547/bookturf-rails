module Api::V0::Contracts::Venues
  class VenueContract < Dry::Validation::Contract
    params do
      required(:name).filled(:string)
      optional(:description).maybe(:string)
      required(:address).filled(:string)
      required(:city).filled(:string)
      required(:state).filled(:string)
      required(:country).filled(:string)
      optional(:postal_code).maybe(:string)
      optional(:latitude).maybe(:decimal)
      optional(:longitude).maybe(:decimal)
      optional(:phone_number).maybe(:string)
      optional(:email).maybe(:string)
      optional(:timezone).maybe(:string)
      optional(:currency).maybe(:string)
      optional(:is_active).maybe(:bool)

      optional(:venue_operating_hours).maybe(:array) do
        each do
          hash do
            required(:day_of_week).filled(:integer)
            optional(:opens_at).maybe(:string)
            optional(:closes_at).maybe(:string)
            optional(:is_closed).maybe(:bool)
          end
        end
      end
    end
  end
end
