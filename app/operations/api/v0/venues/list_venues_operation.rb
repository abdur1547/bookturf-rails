# frozen_string_literal: true

module Api::V0::Venues
  class ListVenuesOperation < BaseOperation
    contract do
      params do
        optional(:page).maybe(:integer)
        optional(:per_page).maybe(:integer)
        optional(:city).maybe(:string)
        optional(:state).maybe(:string)
        optional(:country).maybe(:string)
        optional(:is_active).maybe(:bool)
        optional(:search).maybe(:string)
        optional(:sort_by).maybe(:string, included_in?: Venue.column_names)
        optional(:sort_direction).maybe(:string, included_in?: Constants::ORDER_DIRECTIONS)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venues = current_user.owned_and_member_venues
      return Success(venues: [], json: {}) if venues.empty?
      return Failure(:forbidden) unless authorize?
      @venues = filter_venues(params)
      @venues = search_venues(params[:search]) if params[:search].present?
      @venues = sort_venues(params[:sort_by], params[:sort_direction])
      @venues = paginate_venues(params[:page], params[:per_page])

      json_data = serialize

      Success(venues: @venues, json: json_data)
    end

    private

    attr_reader :params, :current_user, :venues

    def authorize?
      VenuePolicy.new(current_user, venues.first).index?
    end

    def filter_venues(params)
      if params.key?(:is_active)
        if params[:is_active] == true || params[:is_active] == "true"
          @venues = venues.active
        elsif params[:is_active] == false || params[:is_active] == "false"
          @venues = venues.inactive
        end
      else
        @venues = venues.active
      end

      @venues = venues.where(city: params[:city]) if params[:city].present?
      @venues = venues.where(state: params[:state]) if params[:state].present?
      @venues = venues.where(country: params[:country]) if params[:country].present?

      venues
    end

    def search_venues(search_term)
      venues.where(
        "name ILIKE :search OR address ILIKE :search OR city ILIKE :search OR description ILIKE :search",
        search: "%#{search_term}%"
      )
    end

    def sort_venues(sort_field, order_direction)
      venues.order("#{sort_by_value} #{sort_direction_value}")
    end

    def sort_by_value
      Venue.column_names.include?(params[:sort_by]) ? params[:sort_by] : "name"
    end

    def sort_direction_value
      Constants::ORDER_DIRECTIONS.include?(params[:sort_direction]) ? params[:sort_direction] : "asc"
    end

    def paginate_venues(page, per_page)
      page ||= 1
      per_page ||= 10

      page = page.to_i
      per_page = per_page.to_i

      # Handle edge cases
      page = 1 if page < 1
      per_page = 10 if per_page < 1  # Minimum 1 per page
      per_page = 100 if per_page > 100 # Max 100 per page

      offset = (page - 1) * per_page
      venues.limit(per_page).offset(offset)
    end

    def serialize
      Api::V0::VenueBlueprint.render_as_hash(venues)
    end
  end
end
