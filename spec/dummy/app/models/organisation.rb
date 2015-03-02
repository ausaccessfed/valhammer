class Organisation < ActiveRecord::Base
  has_many :resources
  has_many :capabilities

  valhammer
end
