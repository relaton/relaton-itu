RSpec.describe RelatonItu::ItuBibliographicItem do
  it "raises argument error" do
    expect do
      RelatonItu::ItuBibliographicItem.new doctype: "doc"
    end.to output(/invalid doctype/).to_stderr
  end

  it "returns hash" do
    hash = YAML.load_file "spec/examples/itu_bib_item.yml"
    item_hash = RelatonItu::HashConverter.hash_to_bib hash
    item = RelatonItu::ItuBibliographicItem.new item_hash
    item_hash = item.to_hash
    expect(item_hash["editorialgroup"]).to eq hash["editorialgroup"]
  end
end
