module RelatonItu
  class RadioRegulationsParser
    include Relaton::Core::ArrayWrapper

    ROMAN_MONTHS = %w[I II III IV V VI VII VIII IX X XI XII].freeze

    def initialize(hit)
      @hit = hit
    end

    def doc
      @doc ||= hit.hit_collection.agent.get doc_url
    rescue Mechanize::ResponseCodeError, SocketError, Timeout::Error, Errno::ECONNRESET,
            EOFError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
      raise RelatonBib::RequestError, "Could not access #{doc_url}: #{e.message}"
    end

    def doc_url
      CGI.unescape(hit.hit[:url]).split("dest=").last
    end

    def fetch_edition = nil
    def fetch_status = nil
    def fetch_workgroup = nil
    def fetch_abstract = []
    def fetch_relations = []

    def fetch_titles
      title = doc.at("//title")&.text&.strip
      return [] if title.nil? || title.empty?

      RelatonBib::TypedTitleString.from_string title, "en", "Latn"
    end

    def fetch_dates
      array(doc_date).map { |on| { type: "published", on: on } }
    end

    def doc_date
      return @doc_date if defined? @doc_date

      date_str = doc.at("//td[@class='title']/text()")&.text&.slice(/(?<=Year:\s)(?:\d{1,2}\.\w+\.)?\d{4}/)
      @doc_date = date_str ? roman_to_arabic(date_str) : nil
    end

    def fetch_link
      [RelatonBib::TypedUri.new(type: "src", content: doc_url)]
    end

    private

    attr_reader :hit

    # Convert roman month number in string date to arabic number
    # @param date [String]
    # @return [String]
    def roman_to_arabic(date)
      %r{(?<rmonth>[IVX]+)} =~ date
      if ROMAN_MONTHS.index(rmonth)
        month = ROMAN_MONTHS.index(rmonth) + 1
        Date.parse(date.sub(%r{[IVX]+}, month.to_s)).to_s
      else date
      end
    end
  end
end
