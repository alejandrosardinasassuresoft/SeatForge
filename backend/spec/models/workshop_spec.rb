require 'rails_helper'

RSpec.describe Workshop, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      workshop = build(:workshop)
      expect(workshop).to be_valid
    end

    it 'is invalid without a title' do
      workshop = build(:workshop, title: nil)
      expect(workshop).not_to be_valid
      expect(workshop.errors[:title]).to include("can't be blank")
    end

    it 'is invalid without a topic' do
      workshop = build(:workshop, topic: nil)
      expect(workshop).not_to be_valid
      expect(workshop.errors[:topic]).to include("can't be blank")
    end

    it 'defaults active to true' do
      workshop = Workshop.new(title: 'Web Dev', topic: 'Programming')
      expect(workshop.active).to be true
    end
  end

  describe 'scopes' do
    describe '.active_only' do
      it 'returns only active workshops' do
        active_workshop = create(:workshop, active: true)
        inactive_workshop = create(:workshop, active: false)

        results = Workshop.active_only
        expect(results).to include(active_workshop)
        expect(results).not_to include(inactive_workshop)
      end
    end
  end
end
