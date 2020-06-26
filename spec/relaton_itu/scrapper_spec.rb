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
    expect(Net::HTTP).to receive(:get_response).and_raise SocketError
    expect do
      RelatonItu::Scrapper.parse_page url: "https://www.itu.int"
    end.to raise_error RelatonBib::RequestError
  end
end
