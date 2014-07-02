require "spec_helper"

describe Hyper::Cards do
  let(:device) { create(:device) }
  let(:user) { device.user }
  let(:card) { create(:card, user: user) }
  let(:comment) { create(:comment, card: card, user: user) }

  # ======== CREATING CARD COMMENTS ==================
  describe "POST /api/cards/:card_id/comments" do
    it "requires authentication" do
      post "/api/cards/#{card.id}/comments", body: "My card comment"
      expect(response.status).to eql 401 # authentication
      expect(response.header["WWW-Authenticate"]).to eql "Basic realm=\"Hyper\""
    end

    it "creates a new valid comment" do
      http_login device.id, device.access_token
      post "/api/cards/#{card.id}/comments", { body: "My card comment" }, @env
      r = JSON.parse(response.body)
      expect(response.status).to eql 201 # created
      expect(r["body"]).to eql "My card comment"
      comment_id = r["id"]
      expect(comment_id).to_not be_blank
      expect(r["card_id"]).to eql card.id
      expect(r["user_id"]).to eql device.user_id
      expect(r["score"]).to eql 0
      expect(response.header["Location"]).to match "\/comments\/#{comment_id}"
    end

    it "fails for an inexistent card" do
      http_login device.id, device.access_token
      post "/api/cards/#{device.id}/comments", { body: "My card comment" }, @env
      expect(response.status).to eql 404 # not found
    end
  end

  # ======== GETTING CARD COMMENTS ==================
  describe "GET /api/cards/:card_id/comments" do
    it "requires authentication" do
      get "/api/cards/#{card.id}/comments"
      expect(response.status).to eql 401 # authentication
    end

    it "returns the newest comments for a card" do
      create(:comment, card: card)
      http_login device.id, device.access_token
      get "/api/cards/#{card.id}/comments", nil, @env
      expect(response.status).to eql 200
      r = JSON.parse(response.body)
      expect(r.size).to eql(1)
    end

    it "returns the card comments ordered by popularity" do
      new_comment = create(:comment, card: comment.card)
      new_comment.vote_by!(user)
      http_login device.id, device.access_token
      get "/api/cards/#{card.id}/comments", { order_by: "popularity" }, @env
      expect(response.status).to eql 200
      r = JSON.parse(response.body)
      expect(r.size).to eql(2)
      expect(r.first["id"]).to eql(new_comment.id)
      expect(r.map { |c|c["score"] }.uniq).to eql [1, 0]
    end

    it "returns the user comments for the card" do
      create(:comment, user: device.user, card: comment.card)
      http_login device.id, device.access_token
      get "/api/cards/#{card.id}/comments", { user_id: device.user_id }, @env
      expect(response.status).to eql 200
      r = JSON.parse(response.body)
      expect(r.size).to eql(2)
      expect(r.map { |c|c["user_id"] }.uniq).to eql [device.user_id]
    end

    it "accepts pagination" do
      (1..10).map { create(:comment, card: card) }
      http_login device.id, device.access_token
      get "/api/cards/#{card.id}/comments", { page: 2, per_page: 3 }, @env
      expect(response.status).to eql 200
      r = JSON.parse(response.body)
      expect(r.size).to eql(3)
      # response headers
      expect(response.header["Total"]).to eql("10")
      link = "api/cards/#{card.id}/comments?page=3&per_page=3>; rel=\"next\""
      expect(response.header["Link"]).to include(link)
    end
  end
end
