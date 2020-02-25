# frozen_string_literal: true

require "relaton_itu/hit"
require "addressable/uri"
require "net/http"

module RelatonItu
  # Page of hit collection.
  class HitCollection < RelatonBib::HitCollection
    DOMAIN = "https://www.itu.int".freeze

    # @param ref_nbr [String]
    # @param year [String]
    def initialize(ref_nbr, year = nil)
      super
      group = %r{(OB|Operational Bulletin) No} =~ text ? "Publications" : "Recommendations"
      url = "#{DOMAIN}/net4/ITU-T/search/GlobalSearch/Search"
      params = {
        "Input" => ref_nbr,
        "Start" => 0,
        "Rows" => 10,
        "SortBy" => "RELEVANCE",
        "ExactPhrase" => false,
        "CollectionName" => "General",
        "CollectionGroup" => group,
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
      @array = doc["results"].map do |h|
        code  = h["Media"]["Name"]
        title = h["Title"]
        url   = h["Redirection"]
        type  = group.downcase[0...-1]
        Hit.new({ code: code, title: title, url: url, type: type }, self)
      end
    end
  end
end
