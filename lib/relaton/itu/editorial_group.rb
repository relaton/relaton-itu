require_relative "group"

module Relaton
  module Itu
    class EditorialGroup < Lutaml::Model::Serializable
      choice(min:1, max:1) do
        attribute :bureau, :string, values: Bureau::VALUES
        attribute :sector, :string
      end

      attribute :group, Group
      attribute :subgroup, Group
      attribute :workgroup, Group

      xml do
        map_element "bureau", to: :bureau
        map_element "sector", to: :sector
        map_element "group", to: :group
        map_element "subgroup", to: :subgroup
      end
    end
  end
end
