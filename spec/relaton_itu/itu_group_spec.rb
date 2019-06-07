RSpec.describe RelatonItu::ItuGroup do
  it "raises argument error" do
    expect do
      RelatonItu::ItuGroup.new type: "work", name: "group"
    end.to raise_error ArgumentError
  end
end
