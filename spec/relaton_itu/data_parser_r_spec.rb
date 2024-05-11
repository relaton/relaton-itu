describe RelatonItu::DataParserR do
  it "parse" do
    expect(described_class).to receive(:fetch_docid).with(:doc).and_return :docid
    expect(described_class).to receive(:fetch_title).with(:doc).and_return :title
    expect(described_class).to receive(:fetch_abstract).with(:doc).and_return :abstract
    expect(described_class).to receive(:fetch_date).with(:doc).and_return :date
    expect(described_class).to receive(:fetch_link).with(:url).and_return :link
    expect(described_class).to receive(:fetch_status).with(:doc).and_return :status
    expect(described_class).to receive(:fetch_doctype).with(:type).and_return :type
    expect(RelatonItu::ItuBibliographicItem).to receive(:new).with(
      docid: :docid, title: :title, abstract: :abstract, date: :date, language: ["en"],
      link: :link, script: ["Latn"], docstatus: :status, type: "standard", doctype: :type
    ).and_return :bib
    expect(described_class.parse(:doc, :url, :type)).to eq :bib
  end

  it "fetch_docid" do
    doc = Nokogiri::HTML <<~HTML
      <html>
        <body>
          <div id="idDocSetPropertiesWebPart">
            <h2>R-REC-1234-5</h2>
          </div>
        </body>
      </html>
    HTML
    docid = described_class.fetch_docid doc
    expect(docid).to be_instance_of Array
    expect(docid.size).to eq 1
    expect(docid.first).to be_instance_of RelatonBib::DocumentIdentifier
    expect(docid.first.type).to eq "ITU"
    expect(docid.first.id).to eq "ITU-R 1234-5"
    expect(docid.first.primary).to be true
  end

  it "fetch_title" do
    doc = Nokogiri::HTML <<~HTML
      <html>
        <body>
          <table>
            <tr>
              <td><h3>Title</h3></td>
              <td></td>
              <td>title</td>
            </tr>
          </table>
        </body>
      </html>
    HTML
    title = described_class.fetch_title doc
    expect(title).to be_instance_of Array
    expect(title.size).to eq 1
    expect(title.first).to be_instance_of RelatonBib::TypedTitleString
    expect(title.first.type).to eq "main"
    expect(title.first.to_s).to eq "title"
    expect(title.first.language).to eq ["en"]
    expect(title.first.script).to eq ["Latn"]
  end

  it "fetch_abstract" do
    doc = Nokogiri::HTML <<~HTML
      <html>
        <body>
          <table>
            <tr>
              <td><h3>Observation</h3></td>
              <td></td>
              <td>abstract</td>
            </tr>
          </table>
        </body>
      </html>
    HTML
    abstract = described_class.fetch_abstract doc
    expect(abstract).to be_instance_of Array
    expect(abstract.size).to eq 1
    expect(abstract.first).to be_instance_of RelatonBib::FormattedString
    expect(abstract.first.content).to eq "abstract"
    expect(abstract.first.language).to eq ["en"]
    expect(abstract.first.script).to eq ["Latn"]
  end

  it "fetch_date" do
    doc = Nokogiri::HTML <<~HTML
      <html>
        <body>
          <table>
            <tr>
              <td><h3>Approval_Date</h3></td>
              <td></td>
              <td>2019-01-01</td>
            </tr>
            <tr>
              <td><h3>Version year</h3></td>
              <td></td>
              <td>2019</td>
            </tr>
          </table>
          <div id="idDocSetPropertiesWebPart">
            <h2>R-REC-1234-5-2020</h2>
          </div>
        </body>
      </html>
    HTML
    date = described_class.fetch_date doc
    expect(date).to be_instance_of Array
    expect(date.size).to eq 3
    expect(date.first).to be_instance_of RelatonBib::BibliographicDate
    expect(date.first.type).to eq "confirmed"
    expect(date.first.on).to eq "2019-01-01"
    expect(date[1].type).to eq "updated"
    expect(date[1].on).to eq "2019"
    expect(date.last.type).to eq "published"
    expect(date.last.on).to eq "2020"
  end

  context "parse_date" do
    it "year-month" do
      date = described_class.parse_date "201901", "confirmed"
      expect(date).to be_instance_of RelatonBib::BibliographicDate
      expect(date.type).to eq "confirmed"
      expect(date.on).to eq "2019-01"
    end

    it "year-month-day" do
      date = described_class.parse_date "1/22/2019", "confirmed"
      expect(date.on).to eq "2019-01-22"
    end
  end

  it "fetch_link" do
    link = described_class.fetch_link "https://www.itu.int"
    expect(link).to be_instance_of Array
    expect(link.size).to eq 1
    expect(link.first).to be_instance_of RelatonBib::TypedUri
    expect(link.first.type).to eq "src"
    expect(link.first.content.to_s).to eq "https://www.itu.int"
  end

  context "fetch_status" do
    it do
      doc = Nokogiri::HTML <<~HTML
        <html>
          <body>
            <table>
              <tr>
                <td><h3>Status</h3></td>
                <td></td>
                <td>In force</td>
              </tr>
            </table>
          </body>
        </html>
      HTML
      status = described_class.fetch_status doc
      expect(status).to be_instance_of RelatonBib::DocumentStatus
      expect(status.stage.value).to eq "In force"
    end
  end

  it "fetch_doctype" do
    doctype = described_class.fetch_doctype "technical-report"
    expect(doctype).to be_instance_of RelatonItu::DocumentType
    expect(doctype.type).to eq "technical-report"
  end
end
