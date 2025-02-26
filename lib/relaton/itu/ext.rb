require_relative "doctype"
require_relative "bureau"
require_relative "editorial_group"
require_relative "question"
require_relative "recommendation_status"
require_relative "meeting"
require_relative "meeting_date"
require_relative "structured_identifier"

module Relaton
  module Itu
    class Ext < Lutaml::Model::Serializable
      attribute :schema_version, :string
      attribute :doctype, Doctype
      attribute :subdoctype, :string
      attribute :flavor, :string
      attribute :editorialgroup, EditorialGroup, collection: true
      attribute :question, Question, collection: true
      attribute :ics, Bib::ICS, collection: true
      attribute :recommendationstatus, RecommendationStatus
      attribute :ip_notice_received, :boolean
      attribute :meeting, Meeting
      attribute :meeting_place, :string
      attribute :meeting_date, MeetingDate
      attribute :intended_type, :string, values: %w[R C TD]
      attribute :source, :string
      attribute :structuredidentifier, StructuredIdentifier

      xml do
        map_attribute "schema-version", to: :schema_version
        map_element "doctype", to: :doctype
        map_element "subdoctype", to: :subdoctype
        map_element "flavor", to: :flavor
        map_element "editorialgroup", to: :editorialgroup
        map_element "question", to: :question
        map_element "ics", to: :ics
        map_element "recommendationstatus", to: :recommendationstatus
        map_element "ip-notice-received", to: :ip_notice_received
        map_element "meeting", to: :meeting
        map_element "meeting-place", to: :meeting_place
        map_element "meeting-date", to: :meeting_date
        map_element "intended-type", to: :intended_type
        map_element "source", to: :source
        map_element "structuredidentifier", to: :structuredidentifier
      end
    end
  end
end
