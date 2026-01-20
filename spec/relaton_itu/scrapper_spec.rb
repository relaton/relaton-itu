RSpec.describe RelatonItu::Scrapper do
  context "parse abstract" do
    xit "warns about server unavailable" do
      doc = Nokogiri::HTML <<~HTML
        <html>
          <body>
            <table>
              <tr>
                <td><span>In force</span></td>
                <td style="color: white">
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
      end.to output(
        /\[relaton-itu\] ERROR: HTTP Service Unavailable:  =>  for  -- Mechanize::ResponseCodeError/,
      ).to_stderr_from_any_process
    end
  end
end
