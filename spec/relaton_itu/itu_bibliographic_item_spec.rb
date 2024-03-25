RSpec.describe RelatonItu::ItuBibliographicItem do
  it "returns hash" do
    hash = YAML.load_file "spec/examples/itu_bib_item.yml"
    item = RelatonItu::ItuBibliographicItem.from_hash hash
    item_hash = item.to_hash
    expect(item_hash["editorialgroup"]).to eq hash["editorialgroup"]
  end

  it "returns AsciiBib" do
    hash = YAML.load_file "spec/examples/itu_bib_item.yml"
    item = RelatonItu::ItuBibliographicItem.from_hash hash
    bib = item.to_asciibib
      .gsub(/(?<=fetched::\s)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
    file = "spec/examples/asciibib.adoc"
    File.write file, bib, encoding: "UTF-8" unless File.exist? file
    expect(bib).to eq File.read(file, encoding: "UTF-8")
      .gsub(/(?<=fetched::\s)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
  end
end
