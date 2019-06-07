RSpec.describe RelatonItu::ItuBibliographicItem do
  it "raises argument error" do
    expect do
      RelatonItu::ItuBibliographicItem.new type: "doc"
    end.to raise_error ArgumentError
  end
end
