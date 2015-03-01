class Organisation < ActiveRecord::Base
  valhammer

  has_many :resources
  has_many :capabilities
end
