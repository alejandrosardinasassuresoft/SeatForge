module Api
  module V1
    class WorkshopsController < ApplicationController
      def index
        workshops = Workshop.active_only

        if params[:topic].present?
          workshops = workshops.where("LOWER(topic) = ?", params[:topic].downcase)
        end

        sort_column = %w[title created_at topic].include?(params[:sort]) ? params[:sort] : "created_at"
        sort_direction = %w[asc desc].include?(params[:order]&.downcase) ? params[:order].downcase : "desc"
        workshops = workshops.order(sort_column => sort_direction)

        page = [params[:page].to_i, 1].max
        per_page = params[:per_page].present? ? [[params[:per_page].to_i, 1].max, 100].min : 10
        total_records = workshops.count
        total_pages = (total_records / per_page.to_f).ceil
        paginated_workshops = workshops.offset((page - 1) * per_page).limit(per_page)

        render json: {
          workshops: paginated_workshops.as_json,
          pagination: {
            current_page: page,
            per_page: per_page,
            total_records: total_records,
            total_pages: total_pages
          }
        }
      end

      def create
        workshop = Workshop.create!(workshop_params)
        render json: workshop, status: :created
      end

      def show
        workshop = Workshop.find(params[:id])
        render json: workshop
      end

      private

      def workshop_params
        params.require(:workshop).permit(:title, :description, :topic, :active)
      end
    end
  end
end
