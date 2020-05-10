RSpec.describe RelatonItu::StructuredIdentifier do
  it "warn if bureau is invalid" do
    expect do
      RelatonItu::StructuredIdentifier.new bureau: "I", docnumber: "I.1"
    end.to output(/invalid bureau/).to_stderr
  end
end
