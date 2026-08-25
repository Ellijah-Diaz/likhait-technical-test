class Category < ApplicationRecord
  MAX_NAME_LENGTH = 100

  has_many :expenses, dependent: :destroy

  # Trim incidental whitespace before validating, so that " Food " cannot be
  # stored alongside an existing "Food".
  normalizes :name, with: ->(name) { name.to_s.strip }

  # `case_sensitive: false` matches the database, whose utf8mb4_0900_ai_ci
  # collation already treats "food" and "Food" as the same value: without it
  # the validation would pass and the unique index would then raise.
  validates :name,
            presence: true,
            length: { maximum: MAX_NAME_LENGTH },
            uniqueness: { case_sensitive: false }
end
