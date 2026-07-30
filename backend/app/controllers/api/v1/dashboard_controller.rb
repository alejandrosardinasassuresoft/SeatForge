module Api
  module V1
    class DashboardController < BaseController
      def show
        metrics = DashboardQuery.new.call(current_time: Time.current)

        render json: metrics
      end
    end
  end
end
