require "relaton/itu/scraper"

RSpec.describe Relaton::Itu::Scraper do
  describe "#docid" do
    it "adds the equivalent ISO identifier from the recommendation header" do
      hit = double("Hit", hit: {
                     code: "ITU-T Y.3500 (08/2014)",
                     url: "http://handle.itu.int/11.1002/1000/12210-en",
                     type: "recommendation",
                   })
      scraper = described_class.new(hit)
      parser = double(
        "RecommendationParser",
        doc: { "iso_number" => "Equivalent standard: ISO/IEC 17788:2014 (Common)" },
      )
      allow(scraper).to receive(:parser).and_return(parser)

      docids = scraper.send(:docid)
      expect(docids.map(&:content)).to eq ["ITU-T Y.3500 (08/2014)", "ISO/IEC 17788"]
      expect(docids.map(&:type)).to eq %w[ITU ISO]
    end

    it "keeps the hyphenated ISO number intact" do
      hit = double("Hit", hit: {
                     code: "ITU-T H.264 (V14) (08/2021)",
                     url: "http://handle.itu.int/11.1002/1000/14659-en",
                     type: "recommendation",
                   })
      scraper = described_class.new(hit)
      parser = double(
        "RecommendationParser",
        doc: { "iso_number" => "Equivalent standard: ISO/IEC 14496-10 (Twinned)" },
      )
      allow(scraper).to receive(:parser).and_return(parser)

      expect(scraper.send(:docid).last.content).to eq "ISO/IEC 14496-10"
    end

    it "adds no ISO identifier for publications without an idrec" do
      hit = double("Hit", hit: {
                     code: "ITU-R RR (2020)",
                     url: "https://www.itu.int/pub/R-REG-RR-2020",
                     type: "publication",
                   })
      scraper = described_class.new(hit)

      expect(scraper.send(:docid).map(&:content)).to eq ["ITU-R RR (2020)"]
    end
  end

  context "when server is unavailable" do
    it "raises RequestError" do
      agent = double "Mechanize agent"
      expect(agent).to receive(:get)
        .and_raise Mechanize::ResponseCodeError.new(Mechanize::Page.new)
      hit_collection = double("Hit collection", agent: agent)
      hit = double(
        "Hit",
        hit_collection: hit_collection,
        hit: { url: "https://www.itu.int/rec/T-REC-G.191/12345-rec", code: "ITU-T G.191", type: "recommendation" },
      )
      expect do
        Relaton::Itu::Scraper.parse_page(hit)
      end.to raise_error(Relaton::RequestError, /Could not access/)
    end
  end
end
