describe RelatonItu::RadioRegulationsParser do
  let(:agent) { instance_double Mechanize }
  let(:hit_collection) { instance_double RelatonItu::HitCollection, agent: agent }
  let(:hit_hash) { { url: "https://example.com/redirect?dest=https%3A%2F%2Fexample.com%2Fdoc" } }
  let(:hit) { instance_double RelatonItu::Hit, hit_collection: hit_collection, hit: hit_hash }
  subject(:parser) { described_class.new hit }

  describe "#doc" do
    it "fetches and returns the document page" do
      page = instance_double Mechanize::Page
      expect(agent).to receive(:get).with("https://example.com/doc").and_return page
      expect(parser.doc).to eq page
    end

    it "memoizes the result" do
      page = instance_double Mechanize::Page
      expect(agent).to receive(:get).once.and_return page
      2.times { parser.doc }
    end

    it "raises RequestError on SocketError" do
      expect(agent).to receive(:get).and_raise SocketError
      expect { parser.doc }.to raise_error RelatonBib::RequestError, /Could not access/
    end

    it "raises RequestError on Timeout::Error" do
      expect(agent).to receive(:get).and_raise Timeout::Error
      expect { parser.doc }.to raise_error RelatonBib::RequestError, /Could not access/
    end
  end
end
