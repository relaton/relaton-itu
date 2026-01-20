# frozen_string_literal: true

require "nokogiri"
require "net/http"
require_relative "recommendation_parser"
require_relative "radio_regulations_parser"

module RelatonItu
  # Scrapper.
  class Scrapper
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
    # @return [Hash]
    def parse_page # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      return unless parser.doc

      ItuBibliographicItem.new(
        id: fetch_id,
        fetched: Date.today.to_s,
        type: "standard",
        docid: docid,
        edition: parser.fetch_edition,
        language: ["en"],
        script: ["Latn"],
        title: parser.fetch_titles,
        doctype: DocumentType.new(type: hit.hit[:type]),
        docstatus: parser.fetch_status,
        ics: [], # fetch_ics(doc),
        date: parser.fetch_dates,
        contributor: fetch_contributors,
        editorialgroup: parser.fetch_workgroup,
        abstract: parser.fetch_abstract,
        copyright: fetch_copyright,
        link: parser.fetch_link,
        relation: parser.fetch_relations,
        place: ["Geneva"],
      )
    end

    private

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

    def fetch_id
      docid.find(&:primary).id.gsub(/[.\s()\/-]/, "")
    end

    # Fetch docid.
    # @return [Hash]
    def docid
      @docid ||= begin
        docids = hit.hit[:code].to_s.split(" | ").map { |c| createdocid(c) }
        docids << createdocid(doc["rec_name"]) if docids.empty?
        docids
      end
    end

    # @param text [String]
    # @return [RelatonBib::DocumentIdentifier]
    def createdocid(text) # rubocop:disable Metrics/MethodLength
      # %r{
      #   ^(?<code>(?:(?:ITU-\w|ISO/IEC)\s)?[^(:]*)
      #   (?:\s\(V(?<version>\d+)\))?
      #   (?:\s\((?:(?<_month>\d{2})/)?(?<_year>\d{4})\))?
      #   (?::[^(]+\((?<buldate>\d{2}\.\w{1,4}\.\d{4})\))?
      #   (?:\s(?<corr>(?:Amd|Cor)\.\s?\d+))?
      #   # (\s\(((?<_cormonth>\d{2})\/)?(?<_coryear>\d{4})\))?
      # }x =~ text.squeeze(" ")
      # corr&.sub!(/\.\s?/, " ")
      # id = [code.sub(/[[:space:]]$/, ""), corr].compact.join " "
      # id += " (V#{version})" if version
      # id += " - #{buldate}" if buldate
      # type = id.match(%r{^\w+}).to_s
      # type = "ITU" if type == "G"
      if text.match?(/^(?:ISO|ETSI)/)
        type = "ISO"
        text.match(/[^(]+/).to_s.strip.squeeze(" ")
      else
        pubid = Pubid.parse(text)
        type = pubid.prefix # == "G" ? "ITU" : pubid.prefix
        pubid.to_s
      end => id
      RelatonBib::DocumentIdentifier.new(type: type, id: id, primary: true)
    end

    # def fetch_data(url)
    #   resp = hit.hit_collection.agent.get url
    #   JSON.parse(resp.body)
    # rescue Mechanize::ResponseCodeError => e
    #   Util.error "HTTP Service Unavailable: #{e.message}"
    #   nil
    # end

    # Scrape Operational Bulletin date.
    # @param doc [Mechanize::Page]
    # @return [String]
    # def ob_date(doc)
    #   pdate = doc.at('//table/tbody/tr/td[contains(text(), "Year:")]')
    #   return unless pdate

    #   roman_to_arabic pdate.text.match(%r{(?<=Year: )(\d{2}.\w+.)?\d{4}}).to_s
    # end

    # Fetch contributors
    # @return [Array<Hash>]
    def fetch_contributors
      return [] unless hit.hit[:code]

      abbrev = hit.hit[:code].sub(/-\w\s.*/, "")
      case abbrev
      when "ITU"
        name = "International Telecommunication Union"
        url = "www.itu.int"
      end
      [{ entity: { name: name, url: url, abbreviation: abbrev }, role: [type: "publisher"] }]
    end

    # Fetch copyright.
    # @return [Array<Hash>]
    def fetch_copyright
      abbreviation = hit.hit[:code].match(/^[^-]+/).to_s
      case abbreviation
      when "ITU"
        name = "International Telecommunication Union"
        url = "www.itu.int"
      end
      [{ owner: [{ name: name, abbreviation: abbreviation, url: url }], from: parser.doc_date }]
    end
  end
end
