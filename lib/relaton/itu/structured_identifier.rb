module Relaton
  module Itu
    class StructuredIdentifier < Lutaml::Model::Serializable
      attribute :bureau, :string, values: Bureau::VALUES
      attribute :docnumber, :string
      attribute :annexid, :string
      attribute :amendment, :integer
      attribute :corrigendum, :integer

      xml do
        map_element "bureau", to: :bureau
        map_element "docnumber", to: :docnumber
        map_element "annexid", to: :annexid
        map_element "amendment", to: :amendment
        map_element "corrigendum", to: :corrigendum
      end
    end
  end
end
