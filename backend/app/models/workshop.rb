class Workshop < ApplicationRecord
  has_many :sessions, dependent: :destroy

  validates :title, presence: true
  validates :topic, presence: true

  scope :active_only, -> { where(active: true) }
end
