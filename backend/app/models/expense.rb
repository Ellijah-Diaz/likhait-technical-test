class Expense < ApplicationRecord
  belongs_to :category

  validates :date, presence: true

  # Money cannot have been spent on a day that has not happened yet. The check
  # lives here as well as in the form because the API is reachable directly,
  # and `date` is NOT NULL in the schema with no database-level bound.
  #
  # `Date.current` resolves in the application time zone, so the boundary is
  # the server's today, not the browser's.
  validates :date,
            comparison: {
              less_than_or_equal_to: ->(_expense) { Date.current },
              message: "cannot be in the future"
            },
            allow_nil: true

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
