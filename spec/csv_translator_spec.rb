require 'spec_helper'

describe  Polo::CSVTranslator do

  let(:netto) do
    AR::Chef.where(name: 'Netto').first
  end

  before(:all) do
    TestData.create_netto
  end

  it 'prevents instantiation if not csv file' do
    expect(Polo::CSVTranslator.new(AR::Chef, "fail")).to raise_error
  end

end
