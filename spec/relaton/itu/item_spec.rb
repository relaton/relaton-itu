describe Relaton::Itu::Item do
  let(:input_yaml) { File.read("spec/fixtures/item.yaml") }
  let(:input_hash) { YAML.safe_load(input_yaml) }
  let(:item) { described_class.from_yaml(input_yaml) }
  let(:output_hash) { YAML.safe_load described_class.to_yaml(item) }

  it "rounds trip" do
    expect(output_hash).to eq input_hash
  end
end
