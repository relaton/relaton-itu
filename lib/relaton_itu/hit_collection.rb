# frozen_string_literal: true

require "relaton_itu/hit"
require "addressable/uri"
require "net/http"

module RelatonItu
  # Page of hit collection.
  class HitCollection < RelatonBib::HitCollection
    DOMAIN = "https://www.itu.int"
    GH_ITU_R = "https://raw.githubusercontent.com/relaton/relaton-data-itu-r/main/"
    INDEX_FILE = "index-v1.yaml"

    # @return [TrueClass, FalseClass]
    attr_reader :gi_imp

    # @return [Mechanize]
    attr_reader :agent

    #
    # @param refid [RelatonItu::Pubid] reference
    #
    def initialize(refid) # rubocop:todo Metrics/MethodLength
      @refid = refid
      text = refid.to_ref.sub(/(?<=\.)Imp\s?(?=\d)/, "")
      super text, refid.year
      @agent = Mechanize.new
      agent.user_agent_alias = "Mac Safari"
      @gi_imp = /\.Imp\d/.match?(refid.to_s)
      @array = []

      case refid.to_ref
      when /^(ITU-T|ITU-R\sRR)/
        request_search
      when /^ITU-R\s/
        request_document
      end
    end

    private

    def request_search
      Util.info "Fetching from www.itu.int ...", key: @refid.to_s
      url = "#{DOMAIN}/net4/ITU-T/search/GlobalSearch/RunSearch"
      data = { json: params.to_json }
      resp = agent.post url, data
      @array = hits JSON.parse(resp.body)
    end

    def request_document # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
      Util.info "Fetching from Relaton repository ...", key: @refid.to_s
      index = Relaton::Index.find_or_create :itu, url: "#{GH_ITU_R}index-v1.zip", file: INDEX_FILE
      row = index.search(@refid.to_ref).min_by { |i| i[:id] }
      return unless row

      uri = URI("#{GH_ITU_R}#{row[:file]}")
      resp = Net::HTTP.get_response(uri)
      return if resp.code == "404"

      hash = YAML.safe_load resp.body
      item_hash = HashConverter.hash_to_bib(hash)
      item_hash[:fetched] = Date.today.to_s
      item = ItuBibliographicItem.new(**item_hash)
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
      input = @refid.dup
      input.year = nil
      {
        "Input" => input.to_s,
        "Start" => 0,
        "Rows" => 20,
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
              "Target" => "/name_s",
              "TypeName" => "CHECKBOX",
              "GetCriteriaType" => 0,
            },
            {
              "Selected" => false,
              "Value" => "",
              "Label" => "Short description",
              "Target" => "/short_description_s",
              "TypeName" => "CHECKBOX",
              "GetCriteriaType" => 0,
            },
            {
              "Selected" => false,
              "Value" => "",
              "Label" => "File content",
              "Target" => "/file",
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
        url   = "#{DOMAIN}#{h['Redirection']}"
        type  = h["Collection"]["Group"].downcase[0...-1]
        Hit.new({ code: code, title: title, url: url, type: type }, self)
      end
    end
  end
end
