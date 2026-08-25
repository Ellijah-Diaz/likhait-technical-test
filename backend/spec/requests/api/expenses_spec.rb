require 'rails_helper'

RSpec.describe "Api::Expenses", type: :request do
  let!(:food_category) { Category.create!(name: "Food") }
  let!(:transport_category) { Category.create!(name: "Transport") }

  describe "GET /api/expenses" do
    # Created in an order that deliberately does not match their expense dates,
    # so that ordering by created_at and ordering by date give different results.
    let!(:oldest) do
      Expense.create!(description: "Lunch", amount: 100.00, category: food_category, date: Date.current - 5)
    end
    let!(:newest) do
      Expense.create!(description: "Taxi", amount: 50.00, category: transport_category, date: Date.current)
    end
    let!(:middle) do
      Expense.create!(description: "Coffee", amount: 25.00, category: food_category, date: Date.current - 2)
    end

    it "returns all expenses with category information" do
      get "/api/expenses"

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(3)
      expect(json.map { |e| e["category"] }).to include("Food", "Transport")
    end

    it "returns expenses ordered by expense date, most recent first" do
      get "/api/expenses"

      json = JSON.parse(response.body)
      expect(json.map { |e| e["id"] }).to eq([ newest.id, middle.id, oldest.id ])
    end

    it "does not order by creation timestamp" do
      # `middle` was inserted last, so ordering by created_at would put it first.
      get "/api/expenses"

      json = JSON.parse(response.body)
      expect(json.first["id"]).not_to eq(middle.id)
    end

    it "places a newly added expense at the top of the list" do
      # The reported bug: an expense added for today appeared mid-list.
      new_expense = Expense.create!(
        description: "Team dinner", amount: 80.00, category: food_category, date: Date.current
      )

      get "/api/expenses"

      json = JSON.parse(response.body)
      expect(json.first["id"]).to eq(new_expense.id)
    end

    it "breaks ties on the same date by most recently created" do
      same_day = Expense.create!(
        description: "Late snack", amount: 12.00, category: food_category, date: newest.date
      )

      get "/api/expenses"

      json = JSON.parse(response.body)
      expect(json.map { |e| e["id"] }.first(2)).to eq([ same_day.id, newest.id ])
    end

    context "when filtering by year and month" do
      # Fixed historical dates, so the expectations do not depend on when the
      # suite happens to run.
      let!(:march_expense) do
        Expense.create!(description: "March", amount: 30.00, category: food_category, date: Date.new(2020, 3, 15))
      end
      let!(:march_last_day) do
        Expense.create!(description: "March end", amount: 35.00, category: food_category, date: Date.new(2020, 3, 31))
      end
      let!(:april_expense) do
        Expense.create!(description: "April", amount: 40.00, category: food_category, date: Date.new(2020, 4, 1))
      end

      it "returns only expenses dated within the requested month" do
        get "/api/expenses", params: { year: 2020, month: 3 }

        json = JSON.parse(response.body)
        expect(json.map { |e| e["id"] }).to contain_exactly(march_expense.id, march_last_day.id)
      end

      it "filters on the expense date rather than the creation timestamp" do
        # Every record in this spec was inserted moments ago, so filtering on
        # created_at would return nothing at all for March 2020.
        get "/api/expenses", params: { year: 2020, month: 3 }

        json = JSON.parse(response.body)
        expect(json).not_to be_empty
        expect(json.map { |e| e["description"] }).to all(start_with("March"))
      end

      it "includes an expense dated on the final day of the month" do
        get "/api/expenses", params: { year: 2020, month: 3 }

        json = JSON.parse(response.body)
        expect(json.map { |e| e["id"] }).to include(march_last_day.id)
      end

      it "excludes an expense dated on the first day of the next month" do
        get "/api/expenses", params: { year: 2020, month: 3 }

        json = JSON.parse(response.body)
        expect(json.map { |e| e["id"] }).not_to include(april_expense.id)
      end
    end
  end

  describe "POST /api/expenses" do
    context "with valid parameters" do
      let(:valid_params) do
        {
          expense: {
            description: "Team Lunch",
            amount: 150.50,
            category_id: food_category.id,
            date: Date.today
          }
        }
      end

      it "creates a new expense" do
        expect {
          post "/api/expenses", params: valid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["description"]).to eq("Team Lunch")
        expect(json["amount"]).to eq(150.5)
      end
    end

    context "with invalid parameters" do
      it "with negative amounts" do
        invalid_params = {
          expense: {
            description: "Invalid expense",
            amount: -100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "with empty descriptions" do
        invalid_params = {
          expense: {
            description: "",
            amount: 100.00,
            category_id: food_category.id,
            date: Date.today
          }
        }

        expect {
          post "/api/expenses", params: invalid_params, as: :json
        }.to change(Expense, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end
end
