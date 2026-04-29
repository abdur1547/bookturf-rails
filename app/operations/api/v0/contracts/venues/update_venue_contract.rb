module Api::V0::Contracts::Venues
  class UpdateVenueContract < Dry::Validation::Contract
    params do
      required(:id).filled(:integer)
      optional(:name).maybe(:string)
      optional(:description).maybe(:string)
      optional(:address).maybe(:string)
      optional(:city).maybe(:string)
      optional(:state).maybe(:string)
      optional(:country).maybe(:string)
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
            optional(:day_of_week).maybe(:integer)
            optional(:opens_at).maybe(:string)
            optional(:closes_at).maybe(:string)
            optional(:is_closed).maybe(:bool)
          end
        end
      end
    end
  end
end
