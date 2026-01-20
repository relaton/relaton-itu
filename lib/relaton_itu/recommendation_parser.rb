module RelatonItu
  # Parse ITU Radio Regulations from XML to Relaton format.
  class RecommendationParser
    include Relaton::Core::ArrayWrapper

    RECHDR = "https://www.itu.int/mws/api/recommendations/getRecHdrDetail?idrec=%{idrec}&lang=en".freeze
    RECEDITIONS = "https://www.itu.int/mws/api/recommendations/getRecEditions?idrec=%{idrec}&lang=en".freeze
    RECSUPPLEMENTS = "https://www.itu.int/mws/api/recommendations/getRecSupplements?idrec=%{idrec}&lang=en".freeze
    IMPLGUIDES = "https://www.itu.int/mws/api/recommendations/getImplGuides?idrec=%{idrec}&lang=en".freeze

    def initialize(hit, idrec, imp)
      @hit = hit
      @idrec = idrec
      @imp = imp
    end

    def doc
      @doc ||= begin
        url = (imp ? IMPLGUIDES : RECHDR ) % { idrec: idrec }
        resp = get_data url
        imp ? resp.first : resp
      end
    end

    # @return [Strign, nil]
    def fetch_edition
      self_edition.dig("Version")
    end

    # Fetch titles.
    # @return [RelatonBib::TypedTitleStringCollection]
    def fetch_titles
      title = imp ? doc["imp_title_e"] : doc["rec_title"]
      return [] if title.nil? || title.empty?

      RelatonBib::TypedTitleString.from_string title, "en", "Latn"
    end

    # Fetch status.
    # @return [RelatonBib::DocumentStatus, NilClass]
    def fetch_status
      inforce = imp ? imp_status : doc["status"]
      return if inforce.nil? || inforce.empty?

      status = inforce == "In force" ? "Published" : "Withdrawal"
      RelatonBib::DocumentStatus.new(stage: status)
    end

    # Fetch dates
    # @return [Array<Hash>]
    def fetch_dates
      array(doc_date).map { |on| { type: "published", on: on } }
    end

    # Fetch workgroup.
    # @return [RelatonItu::EditorialGroup, NilClass]
    def fetch_workgroup
      group = itugroup(doc["sg"])
      EditorialGroup.new(
        bureau: hit.hit[:code].match(/(?<=-)./).to_s, group: group
      )
    end

    # Fetch abstracts.
    # @return [Array<Hash>]
    def fetch_abstract
      array(doc["summary"]).map do |content|
        { content: content, language: "en", script: "Latn" }
      end
    end

    # Fetch links.
    # @return [Array<Hash>]
    def fetch_link
      link = imp ? doc["imp_dms_link"] : doc["handle_id"]
      links = [{ type: "src", content: link }]
      links << typed_link("pdf", doc["handle_id_pdf_link"]) if doc["handle_id_pdf_link"]
      imp_word_link { |wlink| links << typed_link("word", wlink) }
      links
    end

    def doc_date
      return @doc_date if defined? @doc_date

      date = imp ? doc["imp_approval_date"] : doc["approval_date"]
      @doc_date = Date.parse(date).to_s rescue date
    end

    # Fetch relations.
    # @return [Array<Hash>]
    def fetch_relations
      relations = []
      editions.each do |ed|
        next if ed["idrec"] == idrec

        relations << create_relation("hasEdition", ed["title"], ed["rec_name"])
      end

      supplements.each { |supp| relations << create_relation("complementOf", supp["title_text"], supp["rec_name"]) }
      relations
    end

    private

    attr_reader :hit, :idrec, :imp

    # Get data.
    # @param url [String, nil]
    # @return [Array<String, Nokogiri::HTML::Document>]
    def get_data(url)
      JSON.parse request_document(url).body
    end

    def request_document(url)
      hit.hit_collection.agent.get url
    rescue Mechanize::ResponseCodeError, SocketError, Timeout::Error, Errno::ECONNRESET,
            EOFError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
      raise RelatonBib::RequestError, "Could not access #{url}: #{e.message}"
    end

    def editions
      @editions ||= begin
        url = RECEDITIONS % { idrec: idrec }
        get_data(url) || []
      end
    end

    def self_edition
      @self_edition ||= editions.find { |ed| ed["idrec"] == idrec }
    end

    def imp_status
      self_edition.dig("status")
    end

    # @param name [String]
    # @return [RelatonItu::ItuGroup]
    def itugroup(name) # rubocop:disable Metrics/MethodLength
      return if name.nil? || name.empty?

      if name.include? "Study Group"
        type = "study-group"
        acronym = "SG"
      elsif name.include? "Telecommunication Standardization Advisory Group"
        type = "tsag"
        acronym = "TSAG"
      else
        type = "work-group"
        acronym = "WG"
      end
      ItuGroup.new name: name, type: type, acronym: acronym
    end

    def imp_word_link
      return unless doc["imp_dms_link"]
      @doc_page ||= request_document(doc["imp_dms_link"])
      wrd_elm = @doc_page.at("//font[contains(.,'Word')]/../..")
      yield wrd_elm[:href] if block_given? && wrd_elm
    end

    def create_relation(type, title_text, id)
      title = []
      if title_text && !title.empty?
        title << RelatonBib::TypedTitleString.new(content: title_text, language: "en", script: "Latn")
      else
        fref = RelatonBib::FormattedRef.new(content: id, language: "en", script: "Latn")
      end

      did = RelatonBib::DocumentIdentifier.new(id: id, type: "ITU", primary: true)
      item = ItuBibliographicItem.new(title: title, formattedref: fref, docid: [did])
      { type: "hasEdition", bibitem: item }
    end

    def supplements
      @supplements ||= begin
        if imp
          []
        else
          url = RECSUPPLEMENTS % { idrec: idrec }
          get_data(url) || []
        end
      end
    end

    # @param type [String]
    # @param url [Nokogiri::XML::Element]
    def typed_link(type, url)
      { type: type, content: url }
    end
  end
end
