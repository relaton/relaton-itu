# frozen_string_literal: true

require "cgi"
require "json"
require_relative "hit"

module Relaton
  module Itu
    # Page of hit collection.
    class HitCollection < Relaton::Core::HitCollection
      DOMAIN = "https://www.itu.int"
      GH_ITU_R = "https://raw.githubusercontent.com/relaton/relaton-data-itu-r/refs/heads/v2/"
      REC_URL = "#{DOMAIN}/ITU-T/recommendations/rec.aspx?rec=%<rec>s&lang=en".freeze
      RECEDITIONS_URL = "#{DOMAIN}/mws/api/recommendations/getRecEditions?idrec=%<idrec>s&lang=en".freeze
      HANDLE_URL = "http://handle.itu.int/11.1002/1000/%<idrec>s-en".freeze

      def search
        case ref.to_ref
        when %r{^ITU-R\sRR}, %r{\bOB\.|Operational Bulletin}
          request_publication
        when /^ITU-T/
          request_recommendation
        when /^ITU-R\s/
          request_document
        end
      rescue Mechanize::ResponseCodeError, SocketError, Timeout::Error, Errno::ECONNRESET,
              EOFError, Net::ProtocolError, OpenSSL::SSL::SSLError => e
        raise Relaton::RequestError, "Could not access #{ref.to_ref}: #{e.message}"
      end

      def agent
        @agent ||= Mechanize.new.tap { |agent| agent.user_agent_alias = "Mac Safari" }
      end

      private

      # Resolve an ITU-T Recommendation to its editions via the public rec.aspx
      # page (which exposes the record's handle/idrec) and the getRecEditions API.
      # One hit is built per edition, mirroring the multi-result shape the old
      # RunSearch endpoint used to return, so year filtering keeps working.
      def request_recommendation
        Util.info "Fetching from www.itu.int ...", key: ref.to_s
        idrec = fetch_idrec
        return @array = [] unless idrec

        @array = editions(idrec).map { |ed| recommendation_hit(ed) }
      end

      # @return [String, nil] the record's idrec, or nil when the code is unknown
      def fetch_idrec
        url = format(REC_URL, rec: CGI.escape(rec_query))
        agent.get(url).body[%r{11\.1002/1000/(\d+)}, 1]
      rescue Mechanize::ResponseCodeError => e
        raise unless e.response_code == "404" # unknown code => treat as not found

        nil
      end

      # @return [String] the `rec=` value for the rec.aspx lookup
      def rec_query
        ref.suppl ? "#{ref.code} Suppl. #{ref.suppl}" : ref.code
      end

      # @param idrec [String]
      # @return [Array<Hash>] editions of the recommendation
      def editions(idrec)
        JSON.parse agent.get(format(RECEDITIONS_URL, idrec: idrec)).body
      rescue JSON::ParserError
        []
      end

      # @param edition [Hash] a getRecEditions entry
      # @return [Relaton::Itu::Hit]
      def recommendation_hit(edition)
        Hit.new({
          code: "ITU-T #{edition['rec_name']}",
          title: edition["title"],
          url: format(HANDLE_URL, idrec: edition["idrec"]),
          type: "recommendation",
        }, self)
      end

      # Resolve an ITU-R Radio Regulation or Operational Bulletin to its stable
      # /pub landing page, whose id is derivable from the reference.
      def request_publication
        Util.info "Fetching from www.itu.int ...", key: ref.to_s
        return @array = [] unless ref.year

        url = "#{DOMAIN}/pub/#{publication_id}"
        page = fetch_publication_page url
        return @array = [] if page.nil? || page.uri.to_s.match?(/notfound/i)

        hit = Hit.new({ code: publication_code, title: nil, url: url, type: "publication" }, self)
        @array = [hit]
      end

      # @return [Mechanize::Page, nil] nil when the publication does not exist
      def fetch_publication_page(url)
        agent.get url
      rescue Mechanize::ResponseCodeError => e
        raise unless e.response_code == "404" # unknown publication => not found

        nil
      end

      # @return [String] the /pub identifier for RR or OB
      def publication_id
        if ref.code == "RR"
          "R-REG-RR-#{ref.year}"
        else # Operational Bulletin, e.g. OB.1096
          "T-SP-OB.#{ref.code[/\d+/]}-#{ref.year}"
        end
      end

      # @return [String] the docidentifier-friendly code (year only, no month)
      def publication_code
        "#{ref.prefix}-#{ref.sector} #{ref.code} (#{ref.year})"
      end

      def request_document # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
        Util.info "Fetching from Relaton repository ...", key: ref.to_s
        index = Relaton::Index.find_or_create :itu, url: "#{GH_ITU_R}#{INDEXFILE}.zip", file: "#{INDEXFILE}.yaml"
        row = index.search(ref.to_ref).max_by { |i| i[:id] }
        return unless row

        url = "#{GH_ITU_R}#{row[:file]}"
        resp = agent.get url
        return if resp.code == "404"

        item = Item.from_yaml(resp.body).tap { |i| i.fetched = Date.today.to_s }
        hit = Hit.new({ url: url, ref: ref }, self)
        hit.item = item
        @array = [hit]
      end
    end
  end
end
