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
        optional(:sort).maybe(:string)
        optional(:order).maybe(:string)
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @venues = filter_venues(params)
      @venues = search_venues(@venues, params[:search]) if params[:search].present?
      @venues = sort_venues(@venues, params[:sort], params[:order])
      @venues = paginate_venues(@venues, params[:page], params[:per_page])

      json_data = serialize

      Success(venues: @venues, json: json_data)
    end

    private

    attr_reader :params, :current_user, :venues

    def filter_venues(params)
      venues = Venue.all

      # Filter by active status (default: true for public listing)
      # Handle boolean conversion from string params
      if params.key?(:is_active)
        if params[:is_active] == true || params[:is_active] == "true"
          venues = venues.active
        elsif params[:is_active] == false || params[:is_active] == "false"
          venues = venues.inactive
        end
      else
        # Default to active venues if no filter is specified
        venues = venues.active
      end

      venues = venues.where(city: params[:city]) if params[:city].present?
      venues = venues.where(state: params[:state]) if params[:state].present?
      venues = venues.where(country: params[:country]) if params[:country].present?

      venues
    end

    def search_venues(venues, search_term)
      venues.where(
        "name ILIKE :search OR address ILIKE :search OR city ILIKE :search OR description ILIKE :search",
        search: "%#{search_term}%"
      )
    end

    def sort_venues(venues, sort_field, order_direction)
      sort_field ||= "name"
      order_direction ||= "asc"

      case sort_field
      when "name"
        venues.order(name: order_direction.to_sym)
      when "city"
        venues.order(city: order_direction.to_sym)
      when "created_at"
        venues.order(created_at: order_direction.to_sym)
      else
        venues.order(name: :asc)
      end
    end

    def paginate_venues(venues, page, per_page)
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
      Api::V0::VenueBlueprint.render_as_hash(venues, view: :list)
    end
  end
end
