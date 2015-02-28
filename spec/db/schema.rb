ActiveRecord::Schema.define(version: 0) do
  create_table :resources, force: true do |t|
    t.belongs_to :organisation, null: false, default: nil

    t.string :name, null: false, default: nil, limit: 100
    t.string :mail, null: false, default: nil
    t.string :identifier, null: false, default: nil
    t.string :description, null: true, default: nil
    t.integer :age, null: true, default: nil
    t.decimal :gpa, null: false, default: 3.0

    t.timestamps null: false

    t.index :identifier, unique: true
  end

  create_table :capabilities, force: true do |t|
    t.belongs_to :organisation, null: false, default: nil

    t.string :name, null: false, default: nil

    t.timestamps null: false

    t.index [:organisation_id, :name], unique: true
  end

  create_table :organisations, force: true do |t|
    t.string :name, null: false
    t.string :country, null: false
    t.string :city, null: false

    t.timestamps null: false

    t.index [:country, :name], unique: true
    t.index [:city, :name], unique: true
  end
end
