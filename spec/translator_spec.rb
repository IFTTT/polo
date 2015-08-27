require 'spec_helper'

describe Polo::Translator do

  let(:finder) do
    {
      klass: AR::Chef,
      sql: AR::Chef.where(email: 'nettofarah@gmail.com').to_sql
    }
  end

  before(:all) do
    TestData.create_netto
  end

  describe "options" do
    describe "obfuscate: [fields]" do
      it 'scrambles an specific field' do
        translator = Polo::Translator.new([finder], Polo::Configuration.new(obfuscate: [:email]))
        netto = translator.instances.first

        expect(netto.email).to_not be_nil
        expect(netto.email).to_not eq('nettofarah@gmail.com')
      end
    end
  end
end
