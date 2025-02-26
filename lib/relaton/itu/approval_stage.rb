module Relaton
  module Itu
    class ApprovalStage < Lutaml::Model::Serializable
      attribute :process, :string, values: %w[tap aap]
      attribute :content, :string, values: %w[determined in-force a lc ac lj aj na ar ri at sg c tap]

      xml do
        map_attribute "process", to: :process
        map_content to: :content
      end
    end
  end
end
