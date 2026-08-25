require 'rails_helper'

RSpec.describe "Api::Categories", type: :request do
  describe "GET /api/categories" do
    let!(:food) { Category.create!(name: "Food") }
    let!(:transport) { Category.create!(name: "Transport") }
    let!(:supplies) { Category.create!(name: "Supplies") }

    it "returns all categories" do
      get "/api/categories"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
      expect(json.map { |c| c["name"] }).to include("Food", "Transport", "Supplies")
    end

    it "returns categories in alphabetical order" do
      get "/api/categories"

      json = JSON.parse(response.body)
      expect(json.map { |c| c["name"] }).to eq([ "Food", "Supplies", "Transport" ])
    end
  end

  describe "POST /api/categories" do
    # The GET block's fixtures are scoped to that block, so the category the
    # duplicate cases collide with is created here explicitly.
    let!(:existing_category) { Category.create!(name: "Food") }

    context "with a valid name" do
      it "creates the category" do
        expect {
          post "/api/categories", params: { category: { name: "Groceries" } }, as: :json
        }.to change(Category, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("Groceries")
        expect(json["id"]).to be_present
      end

      it "makes the new category available from the index" do
        post "/api/categories", params: { category: { name: "Groceries" } }, as: :json
        get "/api/categories"

        json = JSON.parse(response.body)
        expect(json.map { |c| c["name"] }).to include("Groceries")
      end

      it "strips surrounding whitespace from the name" do
        post "/api/categories", params: { category: { name: "  Groceries  " } }, as: :json

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["name"]).to eq("Groceries")
      end
    end

    context "with an invalid name" do
      it "rejects a blank name" do
        expect {
          post "/api/categories", params: { category: { name: "" } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)["errors"]).to include("Name can't be blank")
      end

      it "rejects a name consisting only of whitespace" do
        expect {
          post "/api/categories", params: { category: { name: "   " } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(422)
      end

      it "rejects a duplicate name" do
        expect {
          post "/api/categories", params: { category: { name: "Food" } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(422)
        expect(JSON.parse(response.body)["errors"]).to include("Name has already been taken")
      end

      it "rejects a duplicate name that differs only by case" do
        # The database collation is case-insensitive, so without a matching
        # validation this would raise instead of returning a 422.
        expect {
          post "/api/categories", params: { category: { name: "fOOd" } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(422)
      end

      it "rejects a name longer than the column allows" do
        expect {
          post "/api/categories", params: { category: { name: "a" * 101 } }, as: :json
        }.not_to change(Category, :count)

        expect(response).to have_http_status(422)
      end
    end
  end
end
