ActiveRecord::Schema.define(version: 0) do
  create_table :resources, force: true do |t|
    t.string :name, null: false, default: nil, limit: 100
    t.string :mail, null: false, default: nil
    t.string :identifier, null: false, default: nil
    t.string :description, null: true, default: nil
    t.integer :age, null: true, default: nil
    t.decimal :gpa, null: false, default: 3.0

    t.index :identifier, unique: true
  end
end
