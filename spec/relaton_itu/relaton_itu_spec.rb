require "jing"

RSpec.describe RelatonItu do
  it "has a version number" do
    expect(RelatonItu::VERSION).not_to be nil
  end

  it "returs grammar hash" do
    hash = RelatonItu.grammar_hash
    expect(hash).to be_instance_of String
    expect(hash.size).to eq 32
  end

  it "gets a code" do
    VCR.use_cassette "code" do
      results = RelatonItu::ItuBibliography.get("ITU-T L.163", nil, {}).to_xml
      expect(results).to include %(<bibitem id="ITU-TL.163" type="standard">)
      expect(results).to include %(<on>2018-11-29</on>)
      expect(results.gsub(/<relation.*<\/relation>/m, ""))
        .not_to include %(<on>2018-11-29</on>)
      expect(results)
        .to include %(<docidentifier type="ITU">ITU-T L.163</docidentifier>)
    end
  end

  it "get document without abstract" do
    VCR.use_cassette "itu_t_g_994_1" do
      bib = RelatonItu::ItuBibliography.get "ITU-T G.994.1"
      expect(bib.docidentifier[0].id).to eq "ITU-T G.994.1"
      expect(bib.abstract.size).to eq 0
    end
  end

  it "encode abstract text" do
    VCR.use_cassette "itu_t_h_264" do
      file = "spec/examples/itu_t_h_264.xml"
      result = RelatonItu::ItuBibliography.get("ITU-T H.264").to_xml
      File.write file, result, encoding: "UTF-8" unless File.exist? file
      expect(result).to be_equivalent_to File.read(file, encoding: "UTF-8")
        .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
    end
  end

  it "gets a code with year" do
    VCR.use_cassette "code_with_year" do
      result = RelatonItu::ItuBibliography.get("ITU-T L.163", "2018", {})
      expect(result).to be_instance_of RelatonItu::ItuBibliographicItem
    end
  end

  it "gets a referece with an year in a code" do
    VCR.use_cassette "year_in_code" do
      result = RelatonItu::ItuBibliography.get("ITU-T L.163 (11/2018)").to_xml
      expect(result).to include %(<on>2018-11-29</on>)
    end
  end

  it "gets Operational Bulletin" do
    VCR.use_cassette "operational_bulletin" do
      result = RelatonItu::ItuBibliography.get "ITU-T OB.1096 - 15.III.2016"
      expect(result.docidentifier[0].id).to eq "ITU-T OB.1096 - 15.III.2016"
    end
  end

  it "gets a documet with 2 identifier" do
    VCR.use_cassette "itu_t_y_3500" do
      result = RelatonItu::ItuBibliography.get "ITU-T Y.3500"
      expect(result.docidentifier[0].id).to eq "ITU-T Y.3500"
      expect(result.docidentifier[0].type).to eq "ITU"
      expect(result.docidentifier[1].id).to eq "ISO/IEC 17788"
      expect(result.docidentifier[1].type).to eq "ISO"
    end
  end

  it "get amendment" do
    VCR.use_cassette "itu_t_g_989_2_amd_1" do
      bib = RelatonItu::ItuBibliography.get "ITU-T G.989.2 Amd 1"
      expect(bib.docidentifier[0].id).to eq "ITU-T G.989.2 Amd 1"
    end
  end

  it do
    VCR.use_cassette "itu_t_h_225_0_v7_2009_amd_1" do
      bib = RelatonItu::ItuBibliography.get "ITU-T H.225.0 v7 (2009) Amd. 1"
      expect(bib.docidentifier[0].id).to eq "ITU-T H.225.0 v7 Amd 1"
    end
  end

  it "get reference with slash in code" do
    VCR.use_cassette "itu_t_g_780_y_1351" do
      bib = RelatonItu::ItuBibliography.get "ITU-T G.780/Y.1351"
      expect(bib.docidentifier[0].id).to eq "ITU-T G.780/Y.1351"
    end
  end

  it "fetch bureau from code" do
    VCR.use_cassette "itu_t_a_13" do
      result = RelatonItu::ItuBibliography.get "ITU-T A.13"
      expect(result.editorialgroup.bureau).to eq "T"
      expect(result.editorialgroup.group.name).to eq "Telecommunication "\
      "Standardization Advisory Group"
    end
  end

  context "fetch supplements" do
    it do
      VCR.use_cassette "itu_t_a_suppl_2" do
        result = RelatonItu::ItuBibliography.get "ITU-T A Suppl. 2"
        expect(result.docidentifier.first.id).to eq "ITU-T A Suppl. 2"
      end
    end

    it "warn when supplement reference is incorrect" do
      VCR.use_cassette "itu_t_g_suppl_47" do
        expect do
          RelatonItu::ItuBibliography.get "ITU-T G.Suppl.47"
        end.to output(/Incorrect reference/).to_stderr
        # expect(result.docidentifier[0].id).to eq "ITU-T G Suppl. 47"
      end
    end
  end

  it "fetch implementers guide" do
    VCR.use_cassette "itu_g_imp_712" do
      result = RelatonItu::ItuBibliography.get "ITU-T G.Imp712"
      xml = result.to_xml
      file = "spec/examples/itu_g_imp_712.xml"
      File.write file, xml, encoding: "UTF-8" unless File.exist? file
      expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8")
        .gsub(/(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s)
    end
  end

  it "return nil if ITU-R not found" do
    VCR.use_cassette "itu_r_1234" do
      result = RelatonItu::ItuBibliography.get "ITU-R 1234"
      expect(result).to be_nil
    end
  end

  it "warns when year is wrong" do
    VCR.use_cassette "wrong_year" do
      expect { RelatonItu::ItuBibliography.get("ITU-T L.163", "1018", {}) }
        .to output(%r{WARNING: no match found online for ITU-T L.163:1018.})
        .to_stderr
    end
  end

  it "fetch hits" do
    VCR.use_cassette "hits" do
      hit_collection = RelatonItu::ItuBibliography.search("ITU-T L.163")
      expect(hit_collection.fetched).to be_falsy
      expect(hit_collection.fetch).to be_instance_of RelatonItu::HitCollection
      expect(hit_collection.fetched).to be_truthy
      expect(hit_collection.first).to be_instance_of RelatonItu::Hit
      expect(hit_collection.to_s).to eq "<RelatonItu::HitCollection:"\
        "#{format('%<id>#.14x', id: hit_collection.object_id << 1)} "\
        "@ref=ITU-T L.163 @fetched=true>"
    end
  end

  it "return string of hit" do
    VCR.use_cassette "hits" do
      hits = RelatonItu::ItuBibliography.search("ITU-T L.163").fetch
      expect(hits.first.to_s).to eq "<RelatonItu::Hit:"\
        "#{format('%<id>#.14x', id: hits.first.object_id << 1)} "\
        '@text="ITU-T L.163" @fetched="true" @fullIdentifier="ITU-TL.163:2018"'\
        ' @title="ITU-T L.163 (11/2018)">'
    end
  end

  it "return xml of hit" do
    VCR.use_cassette "hit_xml" do
      hits = RelatonItu::ItuBibliography.search("ITU-T L.163")
      file_path = "spec/examples/hit.xml"
      xml = hits.first.to_xml bibdata: true
      File.write file_path, xml unless File.exist? file_path
      expect(xml).to be_equivalent_to File.read(file_path).sub(
        /(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s
      )
      schema = Jing.new "spec/examples/isobib.rng"
      errors = schema.validate file_path
      expect(errors).to eq []
    end
  end

  context "fetch ITU-R" do
    it "reccomendation" do
      VCR.use_cassette "itu_r_bo_600_1" do
        bib = RelatonItu::ItuBibliography.get "ITU-R BO.600-1"
        file = "spec/examples/itu_r_bo_600_1.xml"
        xml = bib.to_xml bibdata: true
        File.write file, xml, encoding: "UTF-8" unless File.exist? file
        expect(xml).to be_equivalent_to File.read(file, encoding: "UTF-8").gsub(
          /(?<=<fetched>)\d{4}-\d{2}-\d{2}/, Date.today.to_s
        )
      end
    end

    it "radio regulation" do
      VCR.use_cassette "itu_r_rr_2020" do
        bib = RelatonItu::ItuBibliography.get "ITU-R RR (2020)"
        expect(bib.docidentifier[0].id).to eq "ITU-R RR"
        expect(bib.date[0].on).to eq "2020"
      end
    end

    it "not exosted radio regulation" do
      VCR.use_cassette "itu_r_rr_2014" do
        expect(RelatonItu::ItuBibliography.get("ITU-R RR (2014)")).to be_nil
      end
    end
  end

  it "could not access site" do
    # expect(Net::HTTP).to receive(:post).with(
    #   kind_of(URI), kind_of(String), kind_of(Hash)
    # ).and_raise SocketError
    agent = double "Mechanize agent"
    expect(agent).to receive(:post).and_raise SocketError
    expect(agent).to receive(:user_agent_alias=)
    expect(Mechanize).to receive(:new).and_return agent
    expect do
      RelatonItu::ItuBibliography.search "ITU-T L.163"
    end.to raise_error RelatonBib::RequestError
  end
end
