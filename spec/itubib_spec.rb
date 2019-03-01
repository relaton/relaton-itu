RSpec.describe ItuBib do
  it "has a version number" do
    expect(ItuBib::VERSION).not_to be nil
  end

  it 'gets a code' do
    VCR.use_cassette 'code' do
      results = ItuBib::ItuBibliography.get('ITU-T L.163', nil, {}).to_xml
      expect(results).to include %(<bibitem type="international-standard" id="ITU-TL.163(11/2018)">)
      expect(results).to include %(<on>2018</on>)
      expect(results.gsub(/<relation.*<\/relation>/m, '')).not_to include %(<on>2018</on>)
      expect(results).to include %(<docidentifier type="ITU">ITU-T L.163 (11/2018)</docidentifier>)
    end
  end

  it 'gets a code with year' do
    VCR.use_cassette 'code_with_year' do
      result = ItuBib::ItuBibliography.get('ITU-T L.163', '2018', {})
      expect(result).to be_instance_of IsoBibItem::IsoBibliographicItem
    end
  end

  it 'warns when year is wrong' do
    VCR.use_cassette 'wrong_year' do
      expect { ItuBib::ItuBibliography.get('ITU-T L.163', '1018', {}) }.to output(
        "fetching ITU-T L.163...\n"\
        "WARNING: no match found online for ITU-T L.163:1018. The code must be exactly like it is on the standards website.\n"\
        "(There was no match for 1018, though there were matches found for 2018.)\n"\
        "If you wanted to cite all document parts for the reference, use \"ITU-T L.163 (all parts)\".\n"\
        "If the document is not a standard, use its document type abbreviation (TS, TR, PAS, Guide).\n"
      ).to_stderr
    end
  end

  it "fetch hits" do
    VCR.use_cassette 'hits' do
      hit_collection = ItuBib::ItuBibliography.search('ITU-T L.163')
      expect(hit_collection.fetched).to be_falsy
      expect(hit_collection.fetch).to be_instance_of ItuBib::HitCollection
      expect(hit_collection.fetched).to be_truthy
      expect(hit_collection.first).to be_instance_of ItuBib::Hit
    end
  end

  it 'return string of hit' do
    VCR.use_cassette 'hits' do
      hits = ItuBib::ItuBibliography.search('ITU-T L.163').fetch
      expect(hits.first.to_s).to eq '<ItuBib::Hit:'\
        "#{format('%#.14x', hits.first.object_id << 1)} "\
        '@text="ITU-T L.163" @fetched="true" @fullIdentifier="ITU-T L.163 (11/2018):2018" '\
        '@title="ITU-T L.163 (11/2018)">'
    end
  end

  it 'return xml of hit' do
    VCR.use_cassette 'hit_xml' do
      hits = ItuBib::ItuBibliography.search('ITU-T L.163')
      file_path = 'spec/examples/hit.xml'
      File.write file_path, hits.first.to_xml unless File.exist? file_path
      expect(hits.first.to_xml).to be_equivalent_to File.read(file_path).sub(/2019-02-28/, Date.today.to_s)
    end
  end

  it 'could not access site' do
    expect(Net::HTTP).to receive(:post).with(kind_of(URI), kind_of(String), kind_of(Hash)).and_throw(:msg)
    expect { ItuBib::ItuBibliography.search 'ITU-T L.163' }.to output("Could not access http://www.itu.int\n").to_stderr
  end
end
