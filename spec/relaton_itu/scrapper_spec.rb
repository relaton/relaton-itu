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

  context "parse abstract" do
    it "warns about server unavailable" do
      doc = Nokogiri::HTML <<~HTML
        <html>
          <body>
            <table>
              <tr>
                <td><span>In force</span></td>
                <td>
                  <span id="lbl_dms">
                    <div onclick="this.style.color='purple'; var newWin = window.open('http://www.itu.int/abs.htm'); return false;"></div>
                  </span>
                </td>
              </tr>
            </table>
          </body>
        </html>
      HTML
      agent = double "Mechanize agent"
      expect(agent).to receive(:get).with("http://www.itu.int/abs.htm")
        .and_raise Mechanize::ResponseCodeError.new(Mechanize::Page.new)
      hit_collection = double("Hit collection", agent: agent)
      hit = double "Hit", hit_collection: hit_collection
      expect do
        RelatonItu::Scrapper.send :fetch_abstract, doc, hit
      end.to output(/^HTTP Service Unavailable: .*$/).to_stderr
    end
  end
end
