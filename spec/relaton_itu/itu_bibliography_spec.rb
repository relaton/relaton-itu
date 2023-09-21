describe RelatonItu::ItuBibliography do
  before { RelatonItu.instance_variable_set :@configuration, nil }

  context ".fetch_ref_err" do
    it "warn missed years" do
      refid = RelatonItu::Pubid.parse "ITU-T X.1 (01/2019)"
      missed_years = [2018, 2017]
      expect do
        described_class.send :fetch_ref_err, refid, missed_years
      end.to output(/matches found for `2018`, `2017`/).to_stderr
    end
  end

  context ".isobib_results_filter" do
    it "returns missed years" do
      result = [double(hit: { code: "ITU-T X.1 (01/2019)" })]
      refid = RelatonItu::Pubid.parse "ITU-T X.1 (01/2018)"
      ret = described_class.send :isobib_results_filter, result, refid
      expect(ret[:years]).to eq ["2019"]
    end
  end
end
