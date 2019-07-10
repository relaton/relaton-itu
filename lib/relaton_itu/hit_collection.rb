# frozen_string_literal: true

require "relaton_itu/hit"
require "addressable/uri"
require "net/http"

module RelatonItu
  # Page of hit collection.
  class HitCollection < Array
    DOMAIN = "https://www.itu.int".freeze

    # @return [TrueClass, FalseClass]
    attr_reader :fetched

    # @return [String]
    attr_reader :text

    # @return [String]
    attr_reader :year

    # @param ref_nbr [String]
    # @param year [String]
    def initialize(ref_nbr, year = nil) #(text, hit_pages = nil)
      @text = ref_nbr
      @year = year
      # from, to = nil
      # if year
      #   from = Date.strptime year, "%Y"
      #   to   = from.next_year.prev_day
      # end
      url = "#{DOMAIN}/net4/ITU-T/search/GlobalSearch/Search"
      params = {
        "Input" => ref_nbr,
        "Start" => 0,
        "Rows" => 10,
        "SortBy" => "RELEVANCE",
        "ExactPhrase" => false,
        "CollectionName" => "General",
        "CollectionGroup" => "Recommendations",
        "Sector" => "t",
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
        "ClientData" => { "ip" => "" },
        "Language" => "en",
        "IP" => "",
        "SearchType" => "All",
      }
      data = { json: params.to_json }
      resp  = Net::HTTP.post(URI(url), data.to_json, "Content-Type" => "application/json")
      doc = JSON.parse resp.body
      hits = doc["results"].map do |h|
        code  = h["Media"]["Name"]
        title = h["Title"]
        url   = h["Redirection"]
        Hit.new({ code: code, title: title, url: url }, self)
      end
      concat hits
      @fetched = false
    end

    # @return [RelatonItu::HitCollection]
    def fetch
      workers = RelatonBib::WorkersPool.new 4
      workers.worker(&:fetch)
      each do |hit|
        workers << hit
      end
      workers.end
      workers.result
      @fetched = true
      self
    end

    def to_s
      inspect
    end

    def inspect
      "<#{self.class}:#{format('%#.14x', object_id << 1)} @fetched=#{@fetched}>"
    end
  end
end
