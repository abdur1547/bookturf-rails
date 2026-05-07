# frozen_string_literal: true

module Api::V0::Courts
  class ListCourtsOperation < BaseOperation
    contract do
      params do
        optional(:page).maybe(:integer, gt?: 0)
        optional(:per_page).maybe(:integer, gt?: 0)
        optional(:venue_id).maybe(:integer)
        optional(:court_type_id).maybe(:integer)
        optional(:city).maybe(:string)
        optional(:is_active).maybe(:bool)
        optional(:search).maybe(:string)
        optional(:sort).maybe(:string, included_in?: Court.column_names)
        optional(:order).maybe(:string, included_in?: %w[asc desc])
      end
    end

    def call(params, current_user)
      @params = params
      @current_user = current_user

      @courts = Court.includes(:court_type, :venue, :pricing_rules).all

      # Apply filters
      @courts = @courts.where(venue_id: params[:venue_id]) if params[:venue_id].present?
      @courts = @courts.where(court_type_id: params[:court_type_id]) if params[:court_type_id].present?
      @courts = @courts.where(venues: { city: params[:city] }) if params[:city].present?

      if params.key?(:is_active)
        is_active = params[:is_active] == true || params[:is_active] == "true"
        @courts = is_active ? @courts.active : @courts.inactive
      end

      @courts = search_courts(@courts, params[:search]) if params[:search].present?
      @courts = sort_courts(@courts, params[:sort], params[:order])
      @courts = paginate_courts(@courts, params[:page], params[:per_page])

      json_data = serialize
      Success(courts: @courts, json: json_data)
    end

    private

    attr_reader :params, :current_user, :courts

    def search_courts(courts, query)
      courts.joins(:venue).where(
        "courts.name ILIKE :term OR courts.description ILIKE :term OR venues.name ILIKE :term",
        term: "%#{query}%"
      )
    end

    def sort_courts(courts, sort_field, order_direction)
      sort_field ||= "name"
      order_direction ||= "asc"

      direction = order_direction.to_sym

      courts.order(sort_field => direction)
    end

    def paginate_courts(courts, page, per_page)
      page ||= 1
      per_page ||= 10

      page = page.to_i
      per_page = per_page.to_i
      page = 1 if page < 1
      per_page = 10 if per_page < 1
      per_page = 100 if per_page > 100

      offset = (page - 1) * per_page
      courts.limit(per_page).offset(offset)
    end

    def serialize
      Api::V0::CourtBlueprint.render_as_hash(courts)
    end
  end
end
