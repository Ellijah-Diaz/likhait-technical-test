class Api::CategoriesController < ApplicationController
  def index
    categories = Category.order(:name)
    render json: categories
  end

  def create
    category = Category.new(category_params)

    if category.save
      render json: category, status: :created
    else
      render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    # The unique index is the last line of defence: two concurrent requests can
    # both clear the uniqueness validation before either has committed.
    render json: { errors: [ "Name has already been taken" ] }, status: :unprocessable_entity
  end

  private

  def category_params
    params.require(:category).permit(:name)
  end
end
