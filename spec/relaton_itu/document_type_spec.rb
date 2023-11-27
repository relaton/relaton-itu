describe RelatonItu::DocumentType do
  it "warns if invalid doctype" do
    expect do
      described_class.new type: "doc"
    end.to output(/\[relaton-itu\] WARNING: Invalid doctype: `doc`/).to_stderr_from_any_process
  end
end
