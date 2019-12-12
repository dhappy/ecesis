class CreateCategoriesYears < ActiveRecord::Migration[6.0]
  def change
    create_table :categories_years do |t|
      t.references :category, null: false, foreign_key: true
      t.references :year, null: false, foreign_key: true

      t.timestamps
    end
  end
end
