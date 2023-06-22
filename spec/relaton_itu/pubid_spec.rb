describe RelatonItu::Pubid do
  context ".parse" do
    shared_examples "parse" do |ref, id|
      it { expect(described_class.parse(ref).to_s).to eq id }
    end

    it_behaves_like "parse", "ITU-T T.4", "ITU-T T.4"
    it_behaves_like "parse", "ITU T-REC-T.4", "ITU-T REC T.4"
    it_behaves_like "parse", "ITU-T REC-T.4", "ITU-T REC T.4"
    it_behaves_like "parse", "ITU-T REC-T.4", "ITU-T REC T.4"
    it_behaves_like "parse", "ITU T-REC-T.4-200307-I", "ITU-T REC T.4 (07/2003)"
    it_behaves_like "parse", "ITU T-REC-T.4-200307", "ITU-T REC T.4 (07/2003)"
    it_behaves_like "parse", "ITU-T REC-T.4-200307", "ITU-T REC T.4 (07/2003)"
    it_behaves_like "parse", "ITU-T REC T.4-200307", "ITU-T REC T.4 (07/2003)"
    it_behaves_like "parse", "ITU-T T.4-200307", "ITU-T T.4 (07/2003)"
    it_behaves_like "parse", "ITU-T L.163 (11/2018)", "ITU-T L.163 (11/2018)"
    it_behaves_like "parse", "ITU-T OB.1096 - 15.III.2016", "ITU-T OB.1096 (03/2016)"
    it_behaves_like "parse", "ITU-T G.989.2 Amd 1", "ITU-T G.989.2 Amd 1"
    it_behaves_like "parse", "ITU-T G.989.2 Amd. 1", "ITU-T G.989.2 Amd 1"
    it_behaves_like "parse", "ITU-T A Suppl 2", "ITU-T A Suppl. 2"
    it_behaves_like "parse", "ITU-T A Suppl. 2", "ITU-T A Suppl. 2"
    it_behaves_like "parse", "ITU-T G.Imp712", "ITU-T G.Imp712"
    it_behaves_like "parse", "ITU-R BO.600-1", "ITU-R BO.600-1"
    it_behaves_like "parse", "ITU-R RR (2020)", "ITU-R RR (2020)"
    it_behaves_like "parse", "ITU-T Z.100 Annex F2 (06/2021)", "ITU-T Z.100 Annex F2 (06/2021)"
    it_behaves_like "parse", "ITU-T G.780/Y.1351", "ITU-T G.780/Y.1351"
    it_behaves_like "parse", "ITU-R 52 (2014)", "ITU-R 52 (2014)"

    it "raise error" do
      expect do
        expect { described_class.parse("ITU- T.4") }.to raise_error Parslet::ParseFailed
      end.to output(/\[relaton-itu\] WARNING: ITU- T\.4 is invalid ITU publication identifier/).to_stderr
    end
  end

  context "#to_ref" do
    it { expect(described_class.parse("ITU-T T.4").to_ref).to eq "ITU-T T.4" }
    it { expect(described_class.parse("ITU-T REC T.4").to_ref).to eq "ITU-T T.4" }
    it { expect(described_class.parse("ITU-T REC T.4-200307").to_ref).to eq "ITU-T T.4 (07/2003)" }
    it { expect(described_class.parse("ITU-T G.989.2 Amd 1").to_ref).to eq "ITU-T G.989.2 Amd 1" }
    it { expect(described_class.parse("ITU-R RR (2020)").to_ref).to eq "ITU-R RR (2020)" }
  end

  context "#to_s" do
    it { expect(described_class.parse("ITU-T T.4").to_s).to eq "ITU-T T.4" }
    it { expect(described_class.parse("ITU-T REC T.4").to_s).to eq "ITU-T REC T.4" }
    it { expect(described_class.parse("ITU-T REC T.4-200307").to_s).to eq "ITU-T REC T.4 (07/2003)"}
  end

  context "#roman_to_2digit" do
    subject { described_class.parse("ITU-T T.4") }
    it { expect(subject.send(:roman_to_2digit, "I")).to eq "01" }
    it { expect(subject.send(:roman_to_2digit, "II")).to eq "02" }
    it { expect(subject.send(:roman_to_2digit, "III")).to eq "03" }
    it { expect(subject.send(:roman_to_2digit, "IV")).to eq "04" }
    it { expect(subject.send(:roman_to_2digit, "V")).to eq "05" }
    it { expect(subject.send(:roman_to_2digit, "VI")).to eq "06" }
    it { expect(subject.send(:roman_to_2digit, "VII")).to eq "07" }
    it { expect(subject.send(:roman_to_2digit, "VIII")).to eq "08" }
    it { expect(subject.send(:roman_to_2digit, "IX")).to eq "09" }
    it { expect(subject.send(:roman_to_2digit, "X")).to eq "10" }
    it { expect(subject.send(:roman_to_2digit, "XI")).to eq "11" }
    it { expect(subject.send(:roman_to_2digit, "XII")).to eq "12" }
    it { expect(subject.send(:roman_to_2digit, "11")).to eq "11" }
  end
end
