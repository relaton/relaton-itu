RSpec.describe RelatonItu::XMLParser do
  it "creates item form xml" do
    xml = File.read "spec/examples/hit.xml"
    item = RelatonItu::XMLParser.from_xml xml
    expect(item.to_xml(bibdata: true)).to be_equivalent_to xml
  end

  it "parse ITU group period" do
    xml = <<~END_XML
      <bibdata type="standard">
        <ext>
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
end
