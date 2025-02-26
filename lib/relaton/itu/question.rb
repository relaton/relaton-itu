module Relaton
  module Itu
    class Question < Lutaml::Model::Serializable
      attribute :identifier, :string
      attribute :name, :string

      xml do
        map_element "identifier", to: :identifier
        map_element "name", to: :name
      end
    end
  end
end
