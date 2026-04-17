require_relative "doctype"
require_relative "question"
require_relative "recommendation_status"
require_relative "meeting"
require_relative "meeting_date"
require_relative "structured_identifier"

module Relaton
  module Itu
    class Ext < Bib::Ext
      attribute :doctype, Doctype
      attribute :structuredidentifier, StructuredIdentifier
      attribute :question, Question, collection: true
      attribute :recommendationstatus, RecommendationStatus
      attribute :ip_notice_received, :boolean
      attribute :meeting, Meeting
      attribute :meeting_place, :string
      attribute :meeting_date, MeetingDate
      attribute :intended_type, :string, values: %w[R C TD]
      attribute :source, :string

      xml do
        map_element "question", to: :question
        map_element "recommendationstatus", to: :recommendationstatus
        map_element "ip-notice-received", to: :ip_notice_received
        map_element "meeting", to: :meeting
        map_element "meeting-place", to: :meeting_place
        map_element "meeting-date", to: :meeting_date
        map_element "intended-type", to: :intended_type
        map_element "source", to: :source
      end

      key_value do
        map_element "question", to: :question
        map_element "recommendationstatus", to: :recommendationstatus
        map_element "ip_notice_received", to: :ip_notice_received
        map_element "meeting", to: :meeting
        map_element "meeting_place", to: :meeting_place
        map_element "meeting_date", to: :meeting_date
        map_element "intended_type", to: :intended_type
        map_element "source", to: :source
      end

      def get_schema_version = Relaton.schema_versions["relaton-model-itu"]
    end
  end
end
