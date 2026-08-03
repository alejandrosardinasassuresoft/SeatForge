class SessionSearchQuery
  PER_PAGE_MAX = 50
  SORT_COLUMNS = %w[starts_at capacity created_at].freeze
  DIRECTIONS = %w[asc desc].freeze

  Result = Struct.new(:sessions, :pagination, keyword_init: true)

  def initialize(params = {})
    @params = params
  end

  def call
    sessions = Session.includes(:workshop).where(status: "scheduled")

    sessions = filter_by_date_range(sessions)
    sessions = filter_by_topic(sessions)
    sessions = filter_available_only(sessions)
    sessions = apply_sorting(sessions)

    page = [params.fetch(:page, 1).to_i, 1].max
    per_page = [[params.fetch(:per_page, 10).to_i, 1].max, PER_PAGE_MAX].min
    total = sessions.count
    total_pages = (total / per_page.to_f).ceil

    records = sessions.offset((page - 1) * per_page).limit(per_page)

    Result.new(
      sessions: records,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_records: total,
        total_pages: total_pages
      }
    )
  end

  private

  attr_reader :params

  def filter_by_date_range(sessions)
    sessions = sessions.where("starts_at >= ?", parse_time(params[:from])) if params[:from].present?
    sessions = sessions.where("ends_at <= ?", parse_time(params[:to])) if params[:to].present?
    sessions
  end

  def parse_time(value)
    Time.parse(value.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def filter_by_topic(sessions)
    return sessions if params[:topic].blank?

    sessions.where(workshops: { topic: params[:topic].downcase }).references(:workshop)
  end

  def filter_available_only(sessions)
    return sessions unless params[:available] == "true"

    sessions.where(
      <<~SQL.squish,
        capacity > (
          SELECT COUNT(*) FROM registrations
          WHERE registrations.session_id = sessions.id
            AND (registrations.status = 'confirmed'
              OR (registrations.status = 'held' AND registrations.hold_expires_at > :current_time))
        )
      SQL
      current_time: Time.current
    )
  end

  def apply_sorting(sessions)
    column = SORT_COLUMNS.include?(params[:sort]) ? params[:sort] : "starts_at"
    direction = DIRECTIONS.include?(params[:order]) ? params[:order] : "asc"

    if column == "capacity"
      sessions.order(Arel.sql("capacity #{direction}"))
    else
      sessions.order(column => direction)
    end
  end
end
