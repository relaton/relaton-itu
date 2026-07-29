require "relaton/itu/hit_collection"

RSpec.describe Relaton::Itu::HitCollection do
  describe "#search" do
    context "error handling" do
      let(:ref) { Relaton::Itu::Pubid.parse("ITU-R BO.600-1") }
      subject(:collection) { described_class.new ref }

      before do
        index = double("Index", search: [{ id: "ITU-R BO.600-1", file: "data/r.yaml" }])
        allow(Relaton::Index).to receive(:find_or_create).and_return(index)
      end

      it "raises RequestError on SocketError" do
        allow_any_instance_of(Mechanize).to receive(:get).and_raise SocketError
        expect { collection.search }.to raise_error Relaton::RequestError, /Could not access/
      end

      it "raises RequestError on Timeout::Error" do
        allow_any_instance_of(Mechanize).to receive(:get).and_raise Timeout::Error
        expect { collection.search }.to raise_error Relaton::RequestError, /Could not access/
      end
    end

    context "with ITU-T recommendation (rec.aspx + getRecEditions path)" do
      let(:ref) { Relaton::Itu::Pubid.parse("ITU-T Z.100") }
      subject(:collection) { described_class.new ref }

      let(:rec_page) do
        double("Page", body: %(<a href="http://handle.itu.int/11.1002/1000/14670-en">Z.100</a>))
      end
      let(:editions_resp) do
        double("Response", body: [
          { "idrec" => 14670, "rec_name" => "Z.100 (06/2021)", "title" => "SDL overview" },
          { "idrec" => 14048, "rec_name" => "Z.100 (10/2019)", "title" => "SDL overview" },
        ].to_json)
      end

      before do
        allow_any_instance_of(Mechanize).to receive(:get)
          .with(a_string_including("rec.aspx?rec=Z.100")).and_return(rec_page)
        allow_any_instance_of(Mechanize).to receive(:get)
          .with(a_string_including("getRecEditions?idrec=14670")).and_return(editions_resp)
      end

      it "resolves each edition to a hit" do
        expect { collection.search }.to output(/Fetching from www\.itu\.int/).to_stderr_from_any_process
        expect(collection.size).to eq 2
        expect(collection.first.hit[:code]).to eq "ITU-T Z.100 (06/2021)"
        expect(collection.first.hit[:url]).to eq "http://handle.itu.int/11.1002/1000/14670-en"
        expect(collection.first.hit[:type]).to eq "recommendation"
      end
    end

    context "with an unknown ITU-T recommendation" do
      let(:ref) { Relaton::Itu::Pubid.parse("ITU-T Z.9999") }
      subject(:collection) { described_class.new ref }

      it "returns empty when rec.aspx exposes no handle" do
        allow_any_instance_of(Mechanize).to receive(:get)
          .and_return(double("Page", body: "<html>no match</html>"))

        expect { collection.search }.to output(/Fetching/).to_stderr_from_any_process
        expect(collection).to be_empty
      end

      it "returns empty when rec.aspx responds 404" do
        page = double("Page", code: "404", uri: URI("https://www.itu.int/x"))
        allow_any_instance_of(Mechanize).to receive(:get)
          .and_raise(Mechanize::ResponseCodeError.new(page))

        expect { collection.search }.to output(/Fetching/).to_stderr_from_any_process
        expect(collection).to be_empty
      end
    end

    context "with ITU-R Radio Regulations (publication path)" do
      it "builds a hit for the predictable /pub landing page" do
        page = double("Page", uri: URI("https://www.itu.int/pub/R-REG-RR-2020"))
        allow_any_instance_of(Mechanize).to receive(:get).and_return(page)

        collection = described_class.new Relaton::Itu::Pubid.parse("ITU-R RR (2020)")
        expect { collection.search }.to output(/Fetching/).to_stderr_from_any_process
        expect(collection.size).to eq 1
        expect(collection.first.hit[:url]).to eq "https://www.itu.int/pub/R-REG-RR-2020"
        expect(collection.first.hit[:code]).to eq "ITU-R RR (2020)"
        expect(collection.first.hit[:type]).to eq "publication"
      end

      it "returns empty when the /pub page redirects to notfound" do
        page = double("Page", uri: URI("https://www.itu.int/en/publications/pages/notfound.aspx"))
        allow_any_instance_of(Mechanize).to receive(:get).and_return(page)

        collection = described_class.new Relaton::Itu::Pubid.parse("ITU-R RR (2014)")
        expect { collection.search }.to output(/Fetching/).to_stderr_from_any_process
        expect(collection).to be_empty
      end

      it "returns empty when the /pub page responds 404" do
        page = double("Page", code: "404", uri: URI("https://www.itu.int/pub/x"))
        allow_any_instance_of(Mechanize).to receive(:get)
          .and_raise(Mechanize::ResponseCodeError.new(page))

        collection = described_class.new Relaton::Itu::Pubid.parse("ITU-R RR (2014)")
        expect { collection.search }.to output(/Fetching/).to_stderr_from_any_process
        expect(collection).to be_empty
      end
    end

    context "with Operational Bulletin (publication path)" do
      it "builds a hit for the OB /pub landing page" do
        page = double("Page", uri: URI("https://www.itu.int/pub/T-SP-OB.1096-2016"))
        allow_any_instance_of(Mechanize).to receive(:get).and_return(page)

        collection = described_class.new Relaton::Itu::Pubid.parse("ITU-T OB.1096 - 15.III.2016")
        expect { collection.search }.to output(/Fetching/).to_stderr_from_any_process
        expect(collection.first.hit[:url]).to eq "https://www.itu.int/pub/T-SP-OB.1096-2016"
        expect(collection.first.hit[:code]).to eq "ITU-T OB.1096 (2016)"
        expect(collection.first.hit[:type]).to eq "publication"
      end
    end

    context "with ITU-R ref (request_document path)" do
      let(:ref) { Relaton::Itu::Pubid.parse("ITU-R BO.600-1") }
      subject(:collection) { described_class.new ref }

      it "fetches document from index" do
        index = double("Index", search: [{ id: "ITU-R BO.600-1", file: "data/r.yaml" }])
        allow(Relaton::Index).to receive(:find_or_create).and_return(index)
        item = double("Item", fetched: nil, "fetched=": nil)
        resp = double("Response", code: "200", body: "---\ntitle: test")
        allow_any_instance_of(Mechanize).to receive(:get).and_return(resp)
        allow(Relaton::Itu::Item).to receive(:from_yaml).and_return(item)

        expect { collection.search }.to output(/Fetching from Relaton repository/).to_stderr_from_any_process
        expect(collection.size).to eq 1
      end

      it "returns empty when index has no match" do
        index = double("Index", search: [])
        allow(Relaton::Index).to receive(:find_or_create).and_return(index)

        expect { collection.search }.to output(/Fetching from Relaton repository/).to_stderr_from_any_process
        expect(collection).to be_empty
      end

      it "returns empty when response is 404" do
        index = double("Index", search: [{ id: "ITU-R BO.600-1", file: "data/r.yaml" }])
        allow(Relaton::Index).to receive(:find_or_create).and_return(index)
        resp = double("Response", code: "404")
        allow_any_instance_of(Mechanize).to receive(:get).and_return(resp)

        expect { collection.search }.to output(/Fetching from Relaton repository/).to_stderr_from_any_process
        expect(collection).to be_empty
      end

      it "selects the latest version when multiple exist" do
        index = double("Index", search: [
          { id: "ITU-R P.838-3", file: "data/itu-r-p-838-3.yaml" },
          { id: "ITU-R P.838-2", file: "data/itu-r-p-838-2.yaml" },
          { id: "ITU-R P.838-1", file: "data/itu-r-p-838-1.yaml" },
          { id: "ITU-R P.838-0", file: "data/itu-r-p-838-0.yaml" },
        ])
        allow(Relaton::Index).to receive(:find_or_create).and_return(index)
        item = double("Item", fetched: nil, "fetched=": nil)
        resp = double("Response", code: "200", body: "---\ntitle: test")
        allow_any_instance_of(Mechanize).to receive(:get).and_return(resp)
        allow(Relaton::Itu::Item).to receive(:from_yaml).and_return(item)

        ref = Relaton::Itu::Pubid.parse("ITU-R P.838")
        col = described_class.new(ref)
        expect { col.search }.to output(/Fetching from Relaton repository/).to_stderr_from_any_process
        expect(col.size).to eq 1
        expect(col.first.hit[:url]).to include("itu-r-p-838-3.yaml")
      end
    end
  end
end
