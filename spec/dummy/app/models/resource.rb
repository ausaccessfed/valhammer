class Resource < ActiveRecord::Base
  belongs_to :organisation

  enum sex: [:mail, :female]

  valhammer
end
