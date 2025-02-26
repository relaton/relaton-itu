module Relaton
  module Itu
    class Group < Lutaml::Model::Serializable
      class Period < Lutaml::Model::Serializable
        attribute :start, :string
        attribute :end, :string

        xml do
          map_element "start", to: :start
          map_element "end", to: :end
        end
      end

      attribute :type, :string, values: %w[
        tsag study-group focus-group adhoc-group correspondence-group joint-coordination-activity
        working-party working-group rapporteur-group intersector-rapporteur-group regional-group
      ]
      attribute :name, :string, raw: true
      attribute :acronym, :string
      attribute :period, Period

      xml do
        map_element "type", to: :type
        map_element "name", to: :name
        map_element "acronym", to: :acronym
        map_element "period", to: :period
      end
    end
  end
end
