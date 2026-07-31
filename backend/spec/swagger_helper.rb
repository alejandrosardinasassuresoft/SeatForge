require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.3",
      info: {
        title: "SeatForge API",
        version: "v1",
        description: "API for managing workshop session registrations, allocations, and waitlists"
      },
      servers: [
        { url: "http://localhost:3000", description: "Development" }
      ],
      paths: {},
      components: {
        schemas: {
          error: {
            type: :object,
            properties: {
              error: {
                type: :object,
                properties: {
                  code: { type: :string },
                  message: { type: :string },
                  details: { type: :array, items: { type: :string } }
                },
                required: %w[code message details]
              }
            },
            required: %w[error]
          },
          pagination: {
            type: :object,
            properties: {
              current_page: { type: :integer },
              per_page: { type: :integer },
              total_records: { type: :integer },
              total_pages: { type: :integer }
            },
            required: %w[current_page per_page total_records total_pages]
          },
          workshop: {
            type: :object,
            properties: {
              id: { type: :integer },
              title: { type: :string },
              description: { type: :string },
              topic: { type: :string },
              active: { type: :boolean },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            }
          },
          workshop_list: {
            type: :object,
            properties: {
              workshops: { type: :array, items: { "$ref" => "#/components/schemas/workshop" } },
              pagination: { "$ref" => "#/components/schemas/pagination" }
            }
          },
          session_list_item: {
            type: :object,
            properties: {
              id: { type: :integer },
              starts_at: { type: :string, format: "date-time" },
              ends_at: { type: :string, format: "date-time" },
              capacity: { type: :integer },
              status: { type: :string, enum: %w[scheduled cancelled completed] },
              workshop: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  title: { type: :string },
                  topic: { type: :string }
                }
              }
            }
          },
          session: {
            type: :object,
            properties: {
              id: { type: :integer },
              workshop_id: { type: :integer },
              starts_at: { type: :string, format: "date-time" },
              ends_at: { type: :string, format: "date-time" },
              capacity: { type: :integer },
              status: { type: :string, enum: %w[scheduled cancelled completed] },
              created_at: { type: :string, format: "date-time" },
              updated_at: { type: :string, format: "date-time" }
            }
          },
          session_detail: {
            type: :object,
            properties: {
              id: { type: :integer },
              starts_at: { type: :string, format: "date-time" },
              ends_at: { type: :string, format: "date-time" },
              capacity: { type: :integer },
              status: { type: :string, enum: %w[scheduled cancelled completed] },
              workshop: {
                type: :object,
                properties: {
                  id: { type: :integer },
                  title: { type: :string },
                  topic: { type: :string },
                  description: { type: :string }
                }
              },
              availability: {
                type: :object,
                properties: {
                  capacity: { type: :integer },
                  held_count: { type: :integer },
                  confirmed_count: { type: :integer },
                  waitlist_count: { type: :integer },
                  available_seats: { type: :integer }
                }
              },
              created_at: { type: :string, format: "date-time" }
            }
          },
          session_list: {
            type: :object,
            properties: {
              sessions: { type: :array, items: { "$ref" => "#/components/schemas/session_list_item" } },
              pagination: { "$ref" => "#/components/schemas/pagination" }
            }
          },
          attendee: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              email: { type: :string }
            }
          },
          registration_session: {
            type: :object,
            properties: {
              id: { type: :integer },
              starts_at: { type: :string, format: "date-time" },
              ends_at: { type: :string, format: "date-time" },
              workshop_title: { type: :string }
            }
          },
          registration: {
            type: :object,
            properties: {
              id: { type: :integer },
              status: { type: :string, enum: %w[held confirmed waitlisted cancelled expired] },
              session_id: { type: :integer },
              session: { "$ref" => "#/components/schemas/registration_session" },
              hold_expires_at: { type: :string, format: "date-time", nullable: true },
              confirmed_at: { type: :string, format: "date-time", nullable: true },
              cancelled_at: { type: :string, format: "date-time", nullable: true },
              created_at: { type: :string, format: "date-time" }
            }
          },
          attendee_registrations: {
            type: :object,
            properties: {
              attendee: { "$ref" => "#/components/schemas/attendee" },
              registrations: { type: :array, items: { "$ref" => "#/components/schemas/registration" } }
            }
          },
          dashboard_metrics: {
            type: :object,
            properties: {
              upcoming_scheduled_sessions: { type: :integer },
              total_held: { type: :integer },
              total_confirmed: { type: :integer },
              total_waitlisted: { type: :integer },
              expired_holds_today: { type: :integer },
              full_sessions: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    id: { type: :integer },
                    starts_at: { type: :string, format: "date-time" },
                    capacity: { type: :integer },
                    workshop: { type: :string },
                    confirmed: { type: :integer }
                  }
                }
              },
              top_waitlisted_sessions: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    id: { type: :integer },
                    starts_at: { type: :string, format: "date-time" },
                    capacity: { type: :integer },
                    workshop: { type: :string },
                    waitlist_size: { type: :integer }
                  }
                }
              }
            }
          },
          registration_create: {
            type: :object,
            properties: {
              id: { type: :integer },
              status: { type: :string, enum: %w[held confirmed waitlisted cancelled expired] },
              session_id: { type: :integer },
              attendee: { "$ref" => "#/components/schemas/attendee" },
              hold_expires_at: { type: :string, format: "date-time", nullable: true },
              confirmed_at: { type: :string, format: "date-time", nullable: true },
              cancelled_at: { type: :string, format: "date-time", nullable: true },
              created_at: { type: :string, format: "date-time" }
            }
          },
          registration_create_payload: {
            type: :object,
            properties: {
              session_id: { type: :integer },
              attendee: {
                type: :object,
                properties: {
                  name: { type: :string },
                  email: { type: :string }
                },
                required: %w[name email]
              }
            },
            required: %w[session_id attendee]
          }
        }
      }
    }
  }

  config.openapi_format = :yaml
end
