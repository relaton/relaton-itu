require_relative "approval_stage"

module Relaton
  module Itu
    class RecommendationStatus < Lutaml::Model::Serializable
      attribute :from, :string
      attribute :to, :string
      attribute :approvalstage, ApprovalStage
    end
  end
end
