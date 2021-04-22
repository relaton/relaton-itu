RSpec.describe RelatonItu::Scrapper do
  it "returns TSAG workgroup" do
    group = RelatonItu::Scrapper.send(
      :itugroup, "Telecommunication Standardization Advisory Group"
    )
    expect(group.type).to eq "tsag"
  end

  it "returns other workgroup" do
    group = RelatonItu::Scrapper.send(:itugroup, "Work group")
    expect(group.type).to eq "work-group"
  end

  it "raises an access error" do
    agent = double "Mechanize agent"
    hit_collection = double "Hit collection", agent: agent
    expect(agent).to receive(:get).and_raise SocketError
    hit = RelatonItu::Hit.new({ url: "https://www.itu.int" }, hit_collection)
    expect do
      RelatonItu::Scrapper.parse_page hit
    end.to raise_error RelatonBib::RequestError
  end
end
