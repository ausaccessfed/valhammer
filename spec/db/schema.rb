ActiveRecord::Schema.define(version: 0) do
  create_table :people, force: true do |t|
    t.string :name, null: false, default: nil
    t.string :mail, null: false, default: nil
    t.string :identifier, null: false, default: nil

    t.index :identifier, unique: true
  end
end
