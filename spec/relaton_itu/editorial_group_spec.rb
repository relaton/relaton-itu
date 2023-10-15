RSpec.describe RelatonItu::EditorialGroup do
  it "warn if bureau is invalid" do
    expect do
      RelatonItu::EditorialGroup.new bureau: "I", group: { name: "eg" }
    end.to output(/\[relaton-itu\] WARNING: Invalid bureau: `I`/).to_stderr
  end
end
