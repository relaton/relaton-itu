# frozen_string_literal: true

require "cgi"
require_relative "recommendation_parser"
require_relative "radio_regulations_parser"

module Relaton
  module Itu
    # Scraper.
    class Scraper
      attr_reader :hit, :imp

      TYPES = {
        "ISO" => "international-standard",
        "TS" => "technicalSpecification",
        "TR" => "technicalReport",
        "PAS" => "publiclyAvailableSpecification",
        "AWI" => "appruvedWorkItem",
        "CD" => "committeeDraft",
        "FDIS" => "finalDraftInternationalStandard",
        "NP" => "newProposal",
        "DIS" => "draftInternationalStandard",
        "WD" => "workingDraft",
        "R" => "recommendation",
        "Guide" => "guide",
      }.freeze

      def initialize(hit, imp: false)
        @hit = hit
        @imp = imp
      end

      def self.parse_page(hit, imp: false)
        new(hit, imp: imp).parse_page
      end

      # Parse page.
      # @return [Relaton::Itu::ItemData, nil]
      def parse_page # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        return unless parser.doc

        Relaton::Itu::ItemData.new(
          fetched: Date.today.to_s,
          type: "standard",
          docidentifier: docid,
          edition: edition,
          language: ["en"],
          script: ["Latn"],
          title: parser.fetch_titles,
          status: parser.fetch_status,
          date: parser.fetch_dates,
          abstract: parser.fetch_abstract,
          source: parser.fetch_source,
          relation: parser.fetch_relations,
          contributor: fetch_contributors,
          copyright: fetch_copyright,
          place: [Relaton::Bib::Place.new(city: "Geneva")],
          ext: Relaton::Itu::Ext.new(
            doctype: Relaton::Itu::Doctype.new(content: hit.hit[:type]),
            flavor: "itu",
          ),
        )
      end

      private

      def edition
        ed = parser.fetch_edition
        Relaton::Bib::Edition.new(content: ed) if ed
      end

      def idrec
        return @idrec if defined? @idrec

        @idrec = CGI.unescape(hit.hit[:url]).split("/").last.slice(/^\d+(?=-)/)&.to_i
      end

      def parser
        @parser ||= begin
          if idrec
            RecommendationParser.new hit, idrec, imp
          else
            RadioRegulationsParser.new hit
          end
        end
      end

      # Fetch docid.
      # @return [Array<Relaton::Bib::Docidentifier>]
      def docid
        @docid ||= begin
          docids = hit.hit[:code].to_s.split(" | ").map { |c| createdocid(c) }
          docids << createdocid(doc["rec_name"]) if docids.empty?
          iso = iso_docid
          docids << iso if iso
          docids
        end
      end

      # The equivalent ISO/IEC identifier used to come from the search result's
      # media name; it is now re-sourced from the recommendation header's
      # `iso_number` field (e.g. "Equivalent standard: ISO/IEC 17788:2014 (Common)").
      # @return [Relaton::Bib::Docidentifier, nil]
      def iso_docid
        return unless idrec # only recommendations carry an idrec / iso_number

        num = parser.doc && parser.doc["iso_number"]
        id = num && num[%r{ISO(?:/IEC)?(?:/IEEE)?\s+\d[\d-]*}]
        createdocid(id) if id
      end

      # @param text [String]
      # @return [Relaton::Bib::Docidentifier]
      def createdocid(text) # rubocop:disable Metrics/MethodLength
        if text.match?(/^(?:ISO|ETSI)/)
          type = "ISO"
          text.match(/[^(]+/).to_s.strip.squeeze(" ")
        else
          pubid = Pubid.parse(text)
          type = pubid.prefix
          pubid.to_s
        end => id
        Docidentifier.new(type: type, content: id, primary: true)
      end

      # @return [Array<Relaton::Bib::Contributor>]
      def fetch_contributors
        contribs = fetch_publisher_contributors
        eg = fetch_editorial_contributor
        contribs << eg if eg
        contribs
      end

      # @return [Array<Relaton::Bib::Contributor>]
      def fetch_publisher_contributors
        return [] unless hit.hit[:code]

        abbrev = hit.hit[:code].sub(/-\w\s.*/, "")
        case abbrev
        when "ITU"
          name = "International Telecommunication Union"
          url = "www.itu.int"
        end
        org = Relaton::Bib::Organization.new(
          name: [Relaton::Bib::TypedLocalizedString.new(content: name)],
          abbreviation: Relaton::Bib::LocalizedString.new(content: abbrev),
          uri: [Relaton::Bib::Uri.new(content: url)],
        )
        role = Relaton::Bib::Contributor::Role.new(type: "publisher")
        [Relaton::Bib::Contributor.new(organization: org, role: [role])]
      end

      # @return [Relaton::Bib::Contributor, nil]
      def fetch_editorial_contributor
        wg_name = parser.fetch_workgroup
        bureau = hit.hit[:code]&.match(/(?<=-)\w/)&.to_s
        return unless bureau

        org = Relaton::Bib::Organization.new(
          name: [Relaton::Bib::TypedLocalizedString.new(content: "International Telecommunication Union")],
          abbreviation: Relaton::Bib::LocalizedString.new(content: "ITU-#{bureau.upcase}"),
          subdivision: group_subdivision(wg_name),
        )
        role = Relaton::Bib::Contributor::Role.new(
          type: "author",
          description: [Relaton::Bib::LocalizedMarkedUpString.new(content: "committee")],
        )
        Relaton::Bib::Contributor.new(organization: org, role: [role])
      end

      # @param wg_name [String, nil]
      # @return [Array<Relaton::Bib::Subdivision>]
      def group_subdivision(wg_name)
        return [] unless wg_name

        subtype = case wg_name
                  when /Advisory Group/ then "tsag"
                  when /Study Group/ then "study-group"
                  else "work-group"
                  end
        [Relaton::Bib::Subdivision.new(
          type: "technical-committee",
          subtype: subtype,
          name: [Relaton::Bib::TypedLocalizedString.new(content: wg_name)],
        )]
      end

      # @return [Array<Relaton::Bib::Copyright>]
      def fetch_copyright
        abbreviation = hit.hit[:code].match(/^[^-]+/).to_s
        case abbreviation
        when "ITU"
          name = "International Telecommunication Union"
          url = "www.itu.int"
        end
        org = Relaton::Bib::Organization.new(
          name: [Relaton::Bib::TypedLocalizedString.new(content: name)],
          abbreviation: Relaton::Bib::LocalizedString.new(content: abbreviation),
          uri: [Relaton::Bib::Uri.new(content: url)],
        )
        owner = Relaton::Bib::ContributionInfo.new(organization: org)
        year = parser.doc_date&.match(/\d{4}/)&.to_s
        [Relaton::Bib::Copyright.new(from: year, owner: [owner])]
      end
    end
  end
end
