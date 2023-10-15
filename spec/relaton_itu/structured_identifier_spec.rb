RSpec.describe RelatonItu::StructuredIdentifier do
  before { RelatonItu.instance_variable_set :@configuration, nil }

  it "warn if bureau is invalid" do
    expect do
      RelatonItu::StructuredIdentifier.new bureau: "I", docnumber: "I.1"
    end.to output(/\[relaton-itu\] WARNING: Invalid bureau: `I`/).to_stderr
  end
end
