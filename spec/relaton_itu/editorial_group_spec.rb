RSpec.describe RelatonItu::EditorialGroup do
  it "warn if bureau is invalid" do
    expect do
      RelatonItu::EditorialGroup.new bureau: "I", group: { name: "eg" }
    end.to output(/\[relaton-itu\] WARN: Invalid bureau: `I`/).to_stderr_from_any_process
  end
end
