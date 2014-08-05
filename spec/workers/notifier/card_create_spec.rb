require "rails_helper"

RSpec.describe Notifier::CardCreate, type: :worker do
  let(:worker) { Notifier::CardCreate.new }
  let(:card) { create(:card) }
  let(:stack) { card.stack }

  it "performs generating notifications for stack subscribers" do
    expect(Notifier::CardCreate).to receive(:perform_async).twice.
                                    and_return("0001")
    PublicActivity.with_tracking do
      subscription = create(:subscription, stack: stack)
      new_card = create(:card, stack: stack)
      act = new_card.activities.where(key: "card.create").last
      notifications = worker.perform(act.id)
      expect(act.reload).to be_notified
      expect(notifications.size).to eql 2
      notifications.each { |n| expect(n).to be_persisted }
      notifications.each { |n| expect(n).to be_sent }
      expect(stack.user.notifications.unread.count).to eql 1
      expect(subscription.user.notifications.unread.count).to eql 1
    end
  end

  it "does not notify activity owner as a subscriber" do
    expect(Notifier::CardCreate).to receive(:perform_async).twice.
                                    and_return("0001")
    PublicActivity.with_tracking do
      user = create(:user)
      subscription = create(:subscription, stack: stack, user: user)
      new_card = create(:card, stack: stack, user: user)
      act = new_card.activities.where(key: "card.create").last
      notifications = worker.perform(act.id)
      expect(act.reload).to be_notified
      expect(notifications.size).to eql 1
      expect(user.notifications.unread.count).to eql 0
    end
  end
end
