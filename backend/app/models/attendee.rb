class Attendee < ApplicationRecord
  has_many :registrations, dependent: :restrict_with_error

  before_validation :normalize_email

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
