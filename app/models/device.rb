class Device < ActiveRecord::Base
  validates :user_id, presence: true

  belongs_to :user

  before_save :generate_access_token, on: :create
  after_save :get_sns_arn

  scope :recent, -> do
    where.not(last_sign_in_at: nil).order("last_sign_in_at DESC")
  end

  scope :with_arn, -> { where.not(sns_arn: nil) }

  def sign_in!
    self.last_sign_in_at = Time.current
    self.save!
  end

  private

  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while self.class.exists?(access_token: access_token)
  end

  def get_sns_arn
    DeviceSnsWorker.perform_async(id) if push_token_changed?
  end
end
