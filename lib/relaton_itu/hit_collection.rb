# frozen_string_literal: true

require "relaton_itu/hit"
require "addressable/uri"
require "net/http"

module RelatonItu
  # Page of hit collection.
  class HitCollection < RelatonBib::HitCollection
    DOMAIN = "https://www.itu.int"

    # @return [TrueClass, FalseClass]
    attr_reader :gi_imp

    # @return [Mechanize]
    attr_reader :agent

    # @param ref [String]
    # @param year [String]
    def initialize(ref, year = nil) # rubocop:todo Metrics/MethodLength
      text = ref.sub /(?<=\.)Imp\s?(?=\d)/, ""
      super text, year
      @agent = Mechanize.new
      agent.user_agent_alias = "Mac Safari"
      @gi_imp = /\.Imp\d/.match?(ref)

      case ref
      when /^(ITU-T|ITU-R\sRR)/
        request_search
      when /^ITU-R\s([-_.\w]+)$/
        request_document($1.upcase)
      end
    end

    private

    def request_search
      url = "#{DOMAIN}/net4/ITU-T/search/GlobalSearch/Search"
      data = { json: params.to_json }
      resp = agent.post url, data.to_json, "Content-Type" => "application/json"
      @array = hits JSON.parse(resp.body)
    end

    # @param ref [String] a document ref
    def request_document(ref) # rubocop:todo Metrics/MethodLength
      uri = URI::HTTPS.build(
        host: "raw.githubusercontent.com",
        path: "/relaton/relaton-data-itu-r/master/data/#{ref}.yaml"
      )
      resp = Net::HTTP.get_response(uri)
      if resp.code == "404"
        @array = []
        return
      end

      hash = YAML.safe_load resp.body
      item_hash = HashConverter.hash_to_bib(hash)
      item = ItuBibliographicItem.new **item_hash
      hit = Hit.new({ url: uri.to_s }, self)
      hit.fetch = item
      @array = [hit]
    end

    # @return [String]
    def group
      @group ||= case text
                 when %r{OB|Operational Bulletin}, %r{^ITU-R\sRR}
                   "Publications"
                 when %r{^ITU-T} then "Recommendations"
                 end
    end

    # @return [Hash]
    def params # rubocop:disable Metrics/MethodLength
      {
        "Input" => text,
        "Start" => 0,
        "Rows" => 10,
        "SortBy" => "RELEVANCE",
        "ExactPhrase" => false,
        "CollectionName" => "General",
        "CollectionGroup" => group,
        "Sector" => text.match(/(?<=^ITU-)\w/).to_s.downcase,
        "Criterias" => [{
          "Name" => "Search in",
          "Criterias" => [
            {
              "Selected" => false,
              "Value" => "",
              "Label" => "Name",
              "Target" => "\\/name_s",
              "TypeName" => "CHECKBOX",
              "GetCriteriaType" => 0,
            },
            {
              "Selected" => false,
              "Value" => "",
              "Label" => "Short description",
              "Target" => "\\/short_description_s",
              "TypeName" => "CHECKBOX",
              "GetCriteriaType" => 0,
            },
            {
              "Selected" => false,
              "Value" => "",
              "Label" => "File content",
              "Target" => "\\/file",
              "TypeName" => "CHECKBOX",
              "GetCriteriaType" => 0,
            },
          ],
          "ShowCheckbox" => true,
          "Selected" => false,
        }],
        "Topics" => "",
        "ClientData" => {},
        "Language" => "en",
        "SearchType" => "All",
      }
    end

    # @param data [Hash]
    # @return [Array<RelatonItu::Hit>]
    def hits(data)
      data["results"].map do |h|
        code  = h["Media"]["Name"]
        title = h["Title"]
        url   = h["Redirection"]
        type  = h["Collection"]["Group"].downcase[0...-1]
        Hit.new({ code: code, title: title, url: url, type: type }, self)
      end
    end
  end
end
