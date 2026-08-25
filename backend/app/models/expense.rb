class Expense < ApplicationRecord
  belongs_to :category

  # Newest expense first, by the date the money was actually spent.
  #
  # created_at breaks ties so that an expense recorded today sorts above ones
  # already stored for the same day, and so that the order is deterministic:
  # ordering on `date` alone leaves same-day rows in whatever order the
  # database happens to return them.
  scope :recent_first, -> { order(date: :desc, created_at: :desc) }

  # Expenses whose expense date falls within the given calendar month.
  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    where(date: start_date..start_date.end_of_month)
  }
end
