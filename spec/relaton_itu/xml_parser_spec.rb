RSpec.describe RelatonItu::XMLParser do
  it "creates item form xml" do
    xml = File.read "spec/examples/from_yaml.xml"
    item = RelatonItu::XMLParser.from_xml xml
    expect(item.to_xml(bibdata: true)).to be_equivalent_to xml
  end

  it "parse ITU group period" do
    xml = <<~END_XML
      <bibdata type="standard" schema-version="v1.2.8">
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

  it "warn if XML doesn't have bibitem or bibdata element" do
    item = ""
    expect { item = RelatonItu::XMLParser.from_xml "" }.to output(/can't find bibitem/)
      .to_stderr
    expect(item).to be_nil
  end
end
