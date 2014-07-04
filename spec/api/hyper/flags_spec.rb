require "spec_helper"

describe Hyper::Flags do
  let(:device) { create(:device) }
  let(:user) { device.user }

  # ======== FLAGGING ==================
  describe "POST /api/flags" do
    it "requires authentication" do
      post "/api/flags"
      expect(response.status).to eql 401 # authentication
    end

    it "fails for an inexistent item" do
      http_login device.id, device.access_token
      post "/api/flags", { user_id: device.id }, @env
      expect(response.status).to eql 404
    end

    it "flags an existent user" do
      http_login device.id, device.access_token
      post "/api/flags", { user_id: user.id }, @env
      expect(response.status).to eql 204
    end

    it "flags an existent card" do
      card = create(:card)
      http_login device.id, device.access_token
      post "/api/flags", { card_id: card.id }, @env
      expect(response.status).to eql 204
    end

    it "flags an existent comment" do
      comment = create(:comment)
      http_login device.id, device.access_token
      post "/api/flags", { comment_id: comment.id }, @env
      expect(response.status).to eql 204
    end
  end
end