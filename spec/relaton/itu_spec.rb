require "jing"

RSpec.describe Relaton::Itu do
  it "has a version number" do
    expect(Relaton::Itu::VERSION).not_to be nil
  end

  it "returs grammar hash" do
    hash = Relaton::Itu.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "gets a code" do
    VCR.use_cassette "code" do
      results = Relaton::Itu::Bibliography.get("ITU-T L.163", nil, {}).to_xml
      expect(results).to include %(type="standard")
      expect(results).to include %(schema-version=)
      expect(results).to include %(<on>2018-11-29</on>)
      expect(results.gsub(/<relation.*<\/relation>/m, ""))
        .not_to include %(<on>2018-11-29</on>)
      expect(results)
        .to include %{<docidentifier type="ITU" primary="true">ITU-T L.163 (11/2018)</docidentifier>}
    end
  end

  it "encode abstract text" do
    VCR.use_cassette "itu_t_h_264" do
      file = "spec/fixtures/itu_t_h_264.xml"
      result = Relaton::Itu::Bibliography.get("ITU-T H.264 (08/2021)").to_xml
      File.write file, result, encoding: "UTF-8" unless File.exist? file
      expect(result).to be_equivalent_to File.read(file, encoding: "UTF-8")
        .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
    end
  end

  it "gets a code with year" do
    VCR.use_cassette "code_with_year" do
      result = Relaton::Itu::Bibliography.get("ITU-T L.163", "2018", {})
      expect(result).to be_instance_of Relaton::Itu::ItemData
    end
  end

  it "gets a referece with an year in a code" do
    VCR.use_cassette "year_in_code" do
      result = Relaton::Itu::Bibliography.get("ITU-T L.163 (11/2018)").to_xml
      expect(result).to include %(<on>2018-11-29</on>)
    end
  end

  it "gets Operational Bulletin" do
    VCR.use_cassette "operational_bulletin" do
      result = Relaton::Itu::Bibliography.get "ITU-T OB.1096 - 15.III.2016"
      expect(result.docidentifier[0].content).to eq "ITU-T OB.1096 (2016)"
    end
  end

  it "gets a documet with 2 identifier" do
    VCR.use_cassette "itu_t_y_3500" do
      result = Relaton::Itu::Bibliography.get "ITU-T Y.3500", "2014"
      expect(result.docidentifier[0].content).to eq "ITU-T Y.3500 (08/2014)"
      expect(result.docidentifier[0].type).to eq "ITU"
      expect(result.docidentifier[1].content).to eq "ISO/IEC 17788"
      expect(result.docidentifier[1].type).to eq "ISO"
    end
  end

  it "get amendment" do
    VCR.use_cassette "itu_t_g_989_2_amd_1" do
      bib = Relaton::Itu::Bibliography.get "ITU-T G.989.2 Amd 1", "2014"
      expect(bib.docidentifier[0].content).to eq "ITU-T G.989.2 (2014) Amd 1 (04/2016)"
    end
  end

  it "get reference with slash in code" do
    VCR.use_cassette "itu_t_g_780_y_1351" do
      bib = Relaton::Itu::Bibliography.get "ITU-T G.780/Y.1351", "2010"
      expect(bib.docidentifier[0].content).to eq "ITU-T G.780/Y.1351 (07/2010)"
    end
  end

  it "fetch bureau from code" do
    VCR.use_cassette "itu_t_a_13" do
      result = Relaton::Itu::Bibliography.get "ITU-T A.13"
      eg = result.contributor.find do |c|
        c.role.any? { |r| r.description.any? { |d| d.content == "committee" } }
      end
      expect(eg).not_to be_nil
      expect(eg.organization.abbreviation.content).to eq "ITU-T"
      expect(eg.organization.subdivision.first.name.first.content).to eq(
        "Telecommunication Standardization Advisory Group",
      )
    end
  end

  it "ITU-T Z.100", vcr: { cassette_name: "itu_t_z_100" } do
    result = Relaton::Itu::Bibliography.get "ITU-T Z.100", "2021"
    expect(result.docidentifier[0].content).to eq "ITU-T Z.100 (06/2021)"
  end

  context "fetch supplements" do
    it do
      VCR.use_cassette "itu_t_a_suppl_2" do
        result = Relaton::Itu::Bibliography.get "ITU-T A Suppl. 2", "2022"
        expect(result.docidentifier.first.content).to eq "ITU-T A Suppl. 2 (12/2022)"
      end
    end

    it "warn when supplement reference is incorrect" do
      VCR.use_cassette "itu_t_g_suppl_47" do
        expect do
          Relaton::Itu::Bibliography.get "ITU-T G.Suppl.47"
        end.to output(/Incorrect reference/).to_stderr_from_any_process
      end
    end
  end

  it "fetch implementers guide" do
    VCR.use_cassette "itu_g_imp_712" do
      result = Relaton::Itu::Bibliography.get "ITU-T G.Imp712 (2000)"
      xml = result.to_xml
      file = "spec/fixtures/itu_g_imp_712.xml"
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
        .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
    end
  end

  it "return nil if ITU-R not found" do
    result = Relaton::Itu::Bibliography.get "ITU-R NO.1234"
    expect(result).to be_nil
  end

  it "warns when year is wrong" do
    VCR.use_cassette "wrong_year" do
      expect { Relaton::Itu::Bibliography.get("ITU-T L.163", "1018", {}) }
        .to output(/There was no match for `1018` year, though there were matches found for `2018` year\./)
        .to_stderr_from_any_process
    end
  end

  it "fetch hits", vcr: { cassette_name: "hits" } do
    hit_collection = Relaton::Itu::Bibliography.search("ITU-T L.163")
    expect(hit_collection.fetched).to be false
    expect(hit_collection.fetch).to be_instance_of Relaton::Itu::HitCollection
    expect(hit_collection.fetched).to be true
    expect(hit_collection.first).to be_instance_of Relaton::Itu::Hit
    expect(hit_collection.to_s).to eq(
      "<Relaton::Itu::HitCollection:" \
      "#{format('%<id>#.14x', id: hit_collection.object_id << 1)} " \
      "@ref=ITU-T L.163 @fetched=true>",
    )
  end

  it "return string of hit" do
    VCR.use_cassette "hits" do
      hits = Relaton::Itu::Bibliography.search("ITU-T L.163")
      hit = hits.first
      hit.item
      expect(hit.to_s).to eq(
        "<Relaton::Itu::Hit:" \
        "#{format('%<id>#.14x', id: hits.first.object_id << 1)} " \
        "@reference=\"ITU-T L.163\" @fetched=\"true\" " \
        "@docidentifier=\"ITU-T L.163 (11/2018)\">",
      )
    end
  end

  it "return xml of hit" do
    VCR.use_cassette "hit_xml" do
      hits = Relaton::Itu::Bibliography.search("ITU-T L.163")
      file_path = "spec/fixtures/hit.xml"
      xml = hits.first.item.to_xml bibdata: true
      File.write file_path, xml unless File.exist? file_path
      expect(xml).to be_equivalent_to File.read(file_path).sub(
        /(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s
      )
      # TODO: uncomment when grammars are updated for the new model
      # schema = Jing.new "grammars/relaton-itu-compile.rng"
      # errors = schema.validate file_path
      # expect(errors).to eq []
    end
  end

  context "fetch ITU-R" do
    it "reccomendation" do
      VCR.use_cassette "itu_r_bo_600_1" do
        bib = Relaton::Itu::Bibliography.get "ITU-R BO.600-1"
        file = "spec/fixtures/itu_r_bo_600_1.xml"
        xml = bib.to_xml(bibdata: true)
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
          .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
      end
    end

    it "radio regulation" do
      VCR.use_cassette "itu_r_rr_2020" do
        bib = Relaton::Itu::Bibliography.get "ITU-R RR (2020)"
        expect(bib.docidentifier[0].content).to eq "ITU-R RR (2020)"
        expect(bib.date[0].at.to_s).to eq "2020"
      end
    end

    it "not existed radio regulation", vcr: "itu_r_rr_2014" do
      expect do
        expect(Relaton::Itu::Bibliography.get("ITU-R RR (2014)")).to be_nil
      end.to output(/Not found\./).to_stderr_from_any_process
    end
  end

  it "could not access site" do
    agent = double "Mechanize agent"
    expect(agent).to receive(:post).and_raise SocketError
    expect(agent).to receive(:user_agent_alias=)
    expect(Mechanize).to receive(:new).and_return agent
    expect do
      Relaton::Itu::Bibliography.search "ITU-T L.163"
    end.to raise_error Relaton::RequestError
  end
end
