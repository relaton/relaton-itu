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

  it "returs relation type other" do
    doc = Nokogiri::HTML File.read "spec/examples/relation_type_other.html"
    relations = RelatonItu::Scrapper.send :fetch_relations, doc
    expect(relations[0][:type]).to eq "other"
  end

  context "returs title" do
    it "empty" do
      title = RelatonItu::Scrapper.send :fetch_titles, title: ""
      expect(title[0][:title_intro]).to be_nil
      expect(title[0][:title_main]).to eq ""
      expect(title[0][:title_part]).to be_nil
    end

    it "with main & part" do
      title = RelatonItu::Scrapper.send :fetch_titles, title: "Main - Part 1:"
      expect(title[0][:title_intro]).to be_nil
      expect(title[0][:title_main]).to eq "Main"
      expect(title[0][:title_part]).to eq "Part 1:"
    end

    it "with intro & main" do
      title = RelatonItu::Scrapper.send :fetch_titles, title: "Intro - Main"
      expect(title[0][:title_intro]).to eq "Intro"
      expect(title[0][:title_main]).to eq "Main"
      expect(title[0][:title_part]).to be_nil
    end

    it "with intro & main & part" do
      title = RelatonItu::Scrapper.send :fetch_titles, title: "Intro - Main - Part 1:"
      expect(title[0][:title_intro]).to eq "Intro"
      expect(title[0][:title_main]).to eq "Main"
      expect(title[0][:title_part]).to eq "Part 1:"
    end

    it "with extra part" do
      title = RelatonItu::Scrapper.send :fetch_titles, title: "Intro - Main - Part 1: - Exra"
      expect(title[0][:title_intro]).to eq "Intro"
      expect(title[0][:title_main]).to eq "Main"
      expect(title[0][:title_part]).to eq "Part 1: -- Exra"
    end
  end
end
