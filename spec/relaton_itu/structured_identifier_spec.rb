RSpec.describe RelatonItu::StructuredIdentifier do
  it "warn if bureau is invalid" do
    expect do
      RelatonItu::StructuredIdentifier.new bureau: "I", docnumber: "I.1"
    end.to output(/\[relaton-itu\] WARN: Invalid bureau: `I`/).to_stderr_from_any_process
  end
end
