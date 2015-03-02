# Valhammer

[![Gem Version][GV img]][Gem Version]
[![Build Status][BS img]][Build Status]
[![Dependency Status][DS img]][Dependency Status]
[![Code Climate][CC img]][Code Climate]
[![Coverage Status][CS img]][Coverage Status]

[Gem Version]: https://rubygems.org/gems/valhammer
[Build Status]: https://travis-ci.org/ausaccessfed/valhammer
[Dependency Status]: https://gemnasium.com/ausaccessfed/valhammer
[Code Climate]: https://codeclimate.com/github/ausaccessfed/valhammer
[Coverage Status]: https://coveralls.io/r/ausaccessfed/valhammer

[GV img]: https://img.shields.io/gem/v/valhammer.svg
[BS img]: https://img.shields.io/travis/ausaccessfed/valhammer/develop.svg
[DS img]: https://img.shields.io/gemnasium/ausaccessfed/valhammer.svg
[CC img]: https://img.shields.io/codeclimate/github/ausaccessfed/valhammer.svg
[CS img]: https://img.shields.io/coveralls/ausaccessfed/valhammer.svg

Automatically validate ActiveRecord models based on the database schema.

Author: Shaun Mangelsdorf

```
Copyright 2015, Australian Access Federation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'valhammer'
```

Use Bundler to install the dependency:

```
bundle install
```

In Rails, Valhammer is automatically added to `ActiveRecord::Base`. If you're
using ActiveRecord outside of Rails, you may have to do this yourself:

```ruby
ActiveRecord::Base.extend(Valhammer::Validations)
```

## Usage

Call the `valhammer` method inside your model class, after any `belongs_to`
relationships are defined:

```ruby
class Widget < ActiveRecord::Base
  belongs_to :supplier

  valhammer
end
```

Generated validations are:

* `:presence` &mdash; added to non-nullable columns
* `:uniqueness` &mdash; added to match unique keys
* `:numericality` &mdash; added to `integer`/`decimal` columns with the
  `only_integer` option set appropriately
* `:length` &mdash; added to `string` columns to ensure the value fits in the
  column

To disable a kind of validation, pass an option to the `valhammer` method:

```ruby
class Widget < ActiveRecord::Base
  belongs_to :supplier

  valhammer uniqueness: false
end
```

## Composite Unique Keys

When Valhammer encounters a composite unique key, it inspects the columns
involved in the key and uses them to build a `scope`. For example:

```ruby
create_table(:widgets) do |t|
  t.string :supplier_code, null: false, default: nil
  t.string :item_code, null: false, default: nil

  t.index [:supplier_code, :item_code], unique: true
end
```

When this table is examined by Valhammer, the uniqueness validation created will
be the same as if you had written:

```ruby
class Widget < ActiveRecord::Base
  validates :item_code, uniqueness: { scope: :supplier_code }
end
```

That is, the last column in the key is the field which gets validated, and the
other columns form the `scope` argument.

## Duplicate Unique Keys

Valhammer is able to handle the simple case when multiple unique keys reference
the same field, as in the following contrived example:

```ruby
create_table(:order_update) do |t|
  t.belongs_to :order
  t.string :state
  t.string :identifier

  t.index [:order_id, :state], unique: true
  t.index [:order_id, :state, :identifier], unique: true
end
```

Uniqueness validations are created as though the model was defined using:

```ruby
class OrderUpdate < ActiveRecord::Base
  validates :state, uniqueness: { scope: :order_id }
  validates :identifier, uniqueness: { scope: [:order_id, :state] }
end
```

In the case where multiple unique keys have the same column in the last
position, Valhammer is unable to determine which is the "authoritative" scope
for the validation. Take the following contrived example:

```ruby
create_table(:order_enquiry) do |t|
  t.belongs_to :order
  t.belongs_to :customer
  t.string :date

  t.index [:order_id, :date], unique: true
  t.index [:customer_id, :date], unique: true
end
```

Valhammer is unable to resolve which `scope` to apply, so no `uniqueness`
validation is applied.

## Unique Keys and Associations

In the case where a foreign key is the last column in a key, that key will not
be given a uniqueness validation.

```ruby
create_table(:order_payment) do |t|
  t.belongs_to :customer
  t.string :reference
  t.boolean :complete
  t.integer :amount

  t.index [:reference, :customer_id], unique: true
end
```

To work around this, put associations first in your unique keys (often a
[good idea](http://dev.mysql.com/doc/refman/5.6/en/multiple-column-indexes.html)
anyway, if it means your association queries benefit from the index).

Alternatively, apply the validation yourself using ActiveRecord.

## Contributing

Refer to [GitHub Flow](https://guides.github.com/introduction/flow/) for
help contributing to this project.
