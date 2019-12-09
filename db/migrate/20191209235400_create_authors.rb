class CreateAuthors < ActiveRecord::Migration[6.0]
  def change
    create_table :authors do |t|
      t.text :name

      t.timestamps
    end
  end
end
