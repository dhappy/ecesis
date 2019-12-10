class CreateAwardsYears < ActiveRecord::Migration[6.0]
  def change
    create_table :awards_years do |t|
      t.references :award
      t.references :year

      t.timestamps
    end
  end
end
