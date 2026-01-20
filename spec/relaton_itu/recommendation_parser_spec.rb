describe RelatonItu::RecommendationParser do
  let(:agent) { instance_double Mechanize }
  let(:hit_collection) { instance_double RelatonItu::HitCollection, agent: agent }
  let(:hit) { instance_double RelatonItu::Hit, hit_collection: hit_collection }
  let(:idrec) { 12345 }
  let(:img) { false }
  subject(:parser) { described_class.new hit, idrec, img }

  describe "#itugroup" do
    it "returns TSAG workgroup" do
      group = subject.send(:itugroup, "Telecommunication Standardization Advisory Group")
      expect(group.type).to eq "tsag"
    end

    it "returns other workgroup" do
      group = subject.send(:itugroup, "Work group")
      expect(group.type).to eq "work-group"
    end
  end

  it "raises an access error" do
    expect(agent).to receive(:get).and_raise SocketError
    expect do
      parser.doc
    end.to raise_error RelatonBib::RequestError
  end
end
