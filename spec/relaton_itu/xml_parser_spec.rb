RSpec.describe RelatonItu::XMLParser do
  it "creates item form xml" do
    xml = File.read "spec/examples/from_yaml.xml"
    item = RelatonItu::XMLParser.from_xml xml
    expect(item.to_xml(bibdata: true)).to be_equivalent_to xml
  end

  it "parse ITU group period" do
    xml = <<~END_XML
      <bibdata type="standard" schema-version="v1.2.9">
        <ext schema-version="v1.0.0">
          <editorialgroup>
            <bureau>T</bureau>
            <group type="study-group">
              <name>ITU-T Study Group 15</name>
              <acronym>SG</acronym>
              <period><start>2005</start><end>2015</end></period>
            </group>
          </editorialgroup>
        </ext>
      </bibdata>
    END_XML
    item = RelatonItu::XMLParser.from_xml xml
    expect(item.editorialgroup.group.period).to be_instance_of RelatonItu::ItuGroup::Period
    expect(item.to_xml(bibdata: true)).to be_equivalent_to xml
  end

  # it "warn if XML doesn't have bibitem or bibdata element" do
  #   item = ""
  #   expect { item = RelatonItu::XMLParser.from_xml "" }.to output(/can't find bibitem/)
  #     .to_stderr
  #   expect(item).to be_nil
  # end

  it "create_doctype" do
    type = double "type", text: "type"
    expect(type).to receive(:[]).with(:abbreviation).and_return("ABBREV")
    dt = described_class.send :create_doctype, type
    expect(dt).to be_instance_of RelatonItu::DocumentType
    expect(dt.type).to eq "type"
    expect(dt.abbreviation).to eq "ABBREV"
  end

  describe ".fetch_editorialgroup" do
    it "creates editorial group from XML" do
      xml = <<~END_XML
        <ext>
          <editorialgroup>
            <bureau>T</bureau>
            <group type="study-group">
              <name>ITU-T Study Group 15</name>
              <acronym>SG15</acronym>
            </group>
            <subgroup type="work-group">
              <name>Working Party 1</name>
              <acronym>WP1</acronym>
            </subgroup>
            <workgroup type="tsag">
              <name>Rapporteur Group 1</name>
              <acronym>RG1</acronym>
            </workgroup>
          </editorialgroup>
        </ext>
      END_XML
      doc = Nokogiri::XML(xml)
      ext = doc.at("ext")
      group = described_class.send(:fetch_editorialgroup, ext)

      expect(group).to be_instance_of(RelatonItu::EditorialGroup)
      expect(group.bureau).to eq("T")
      expect(group.group.name).to eq("ITU-T Study Group 15")
      expect(group.group.acronym).to eq("SG15")
      expect(group.subgroup.name).to eq("Working Party 1")
      expect(group.subgroup.acronym).to eq("WP1")
      expect(group.workgroup.name).to eq("Rapporteur Group 1")
      expect(group.workgroup.acronym).to eq("RG1")
    end

    it "returns nil when no editorialgroup element" do
      xml = "<ext></ext>"
      doc = Nokogiri::XML(xml)
      ext = doc.at("ext")
      group = described_class.send(:fetch_editorialgroup, ext)
      expect(group).to be_nil
    end

    it "returns nil when ext is nil" do
      group = described_class.send(:fetch_editorialgroup, nil)
      expect(group).to be_nil
    end

    it "returns nil when ext is empty" do
      xml = "<ext></ext>"
      doc = Nokogiri::XML(xml)
      ext = doc.at("ext")
      group = described_class.send(:fetch_editorialgroup, ext)
      expect(group).to be_nil
    end

    it "returns nil when ext has no editorialgroup element" do
      xml = "<ext><other>content</other></ext>"
      doc = Nokogiri::XML(xml)
      ext = doc.at("ext")
      group = described_class.send(:fetch_editorialgroup, ext)
      expect(group).to be_nil
    end
  end

  describe ".itugroup" do
    it "creates ITU group from XML" do
      xml = <<~END_XML
        <group type="study-group">
          <name>ITU-T Study Group 15</name>
          <acronym>SG15</acronym>
          <period>
            <start>2005</start>
            <end>2015</end>
          </period>
        </group>
      END_XML
      doc = Nokogiri::XML(xml)
      group = doc.at("group")
      itu_group = described_class.send(:itugroup, group)

      expect(itu_group).to be_instance_of(RelatonItu::ItuGroup)
      expect(itu_group.type).to eq("study-group")
      expect(itu_group.name).to eq("ITU-T Study Group 15")
      expect(itu_group.acronym).to eq("SG15")
      expect(itu_group.period.start).to eq("2005")
      expect(itu_group.period.finish).to eq("2015")
    end

    it "returns nil when no group element" do
      itu_group = described_class.send(:itugroup, nil)
      expect(itu_group).to be_nil
    end
  end

  describe ".fetch_structuredidentifier" do
    it "creates structured identifier from XML" do
      xml = <<~END_XML
        <ext>
          <structuredidentifier>
            <bureau>T</bureau>
            <docnumber>G.709</docnumber>
            <annexid>A</annexid>
          </structuredidentifier>
        </ext>
      END_XML
      doc = Nokogiri::XML(xml)
      ext = doc.at("ext")
      sid = described_class.send(:fetch_structuredidentifier, ext)

      expect(sid).to be_instance_of(RelatonItu::StructuredIdentifier)
      expect(sid.bureau).to eq("T")
      expect(sid.docnumber).to eq("G.709")
      expect(sid.annexid).to eq("A")
    end

    it "creates structured identifier without annexid" do
      xml = <<~END_XML
        <ext>
          <structuredidentifier>
            <bureau>T</bureau>
            <docnumber>G.709</docnumber>
          </structuredidentifier>
        </ext>
      END_XML
      doc = Nokogiri::XML(xml)
      ext = doc.at("ext")
      sid = described_class.send(:fetch_structuredidentifier, ext)

      expect(sid).to be_instance_of(RelatonItu::StructuredIdentifier)
      expect(sid.bureau).to eq("T")
      expect(sid.docnumber).to eq("G.709")
      expect(sid.annexid).to be_nil
    end

    it "returns nil when no structuredidentifier element" do
      xml = "<ext></ext>"
      doc = Nokogiri::XML(xml)
      ext = doc.at("ext")
      sid = described_class.send(:fetch_structuredidentifier, ext)
      expect(sid).to be_nil
    end
  end
end
