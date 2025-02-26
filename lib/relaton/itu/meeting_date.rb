module Relaton
  module Itu
    class MeetingDate < Lutaml::Model::Serializable
      attribute :from, :string
      attribute :to, :string
      attribute :at, :string

      xml do
        map_element "from", to: :from
        map_element "to", to: :to
        map_element "on", to: :at
      end
    end
  end
end
