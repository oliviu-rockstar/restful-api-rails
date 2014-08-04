class Card < ActiveRecord::Base
  include Votable
  include Flaggable
  include PublicActivity::Model
  tracked owner: :user, recipient: :stack

  validates :name, :stack, :user, presence: true
  attr_readonly :score

  belongs_to :stack
  belongs_to :user
  has_many :images, -> { order("position ASC") },
           class_name: "CardImage",
           dependent: :destroy,
           inverse_of: :card
  accepts_nested_attributes_for :images
  has_many :comments, -> { order("created_at ASC") }

  scope :max_score, ->(score) { where("score <= ?", score) }
  scope :newest, -> { order("created_at DESC") }
  scope :best, -> { order("score DESC") }
  scope :up_voted_by, ->(user_id) { joins(:up_votes).
                                    where("votes.user_id = ?", user_id).
                                    order("votes.created_at DESC")
                                  }

  def to_param
    hash_id
  end

  def hash_id
    self.class.hashids.encrypt(short_id)
  end

  def self.find_by_hash_id!(hash_id)
    self.find_by! short_id: hashids.decrypt(hash_id)
  end

  def self.hashids
    @hashids ||= Hashids.new("Hyper card short_id salt")
  end

  def self.popularity
    select("*, hot_score(up_score, down_score, created_at) as rank").
      order("rank DESC, created_at DESC")
  end
end
