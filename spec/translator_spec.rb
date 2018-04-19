require 'spec_helper'

describe Polo::Translator do

  let(:email) { 'nettofarah@gmail.com' }
  let(:finder) do
    Polo::Collector::SqlRecord.new(AR::Chef, AR::Chef.where(email: email).to_sql)
  end

  before(:all) do
    TestData.create_netto
  end

  describe "options" do
    describe "obfuscate: [fields]" do
      let(:translator) { Polo::Translator.new([finder], Polo::Configuration.new(obfuscate: obfuscated_fields)) }
      let(:netto) { netto = translator.instances.first }

      context "obfuscated field with no specified strategy" do
        let(:obfuscated_fields) {{email: nil }}

        it "shuffles characters in field" do
          expect(netto.email).to_not be_nil
          expect(netto.email.length).to eq email.length
          expect(sorted_characters(netto.email)).to eq sorted_characters(email)
        end
      end

      context "obfuscated field with obscuration strategy applied which will result in 42" do
        let(:obfuscated_fields) {{email: lambda { |_| 42 } } }

        it "replaces contents of field according to the supplied lambda" do
          expect(netto.email.to_s).to eq "42"
        end
      end

      context "complex custom obfuscation strategy" do
        let(:obfuscated_fields) do
          { email: lambda { |field| "temp_#{field}" } }
        end

        it "replaces contents of field according to the supplied lambda" do
          expect(netto.email.to_s).to eq "temp_nettofarah@gmail.com"
        end
      end

      context "custom obfuscation strategy using instance context" do
        let(:obfuscated_fields) do
          { email: lambda { |field, instance| "#{instance.name}@example.com" } }
        end

        it "replaces contents of field according to the supplied lambda" do
          expect(netto.email.to_s).to eq "Netto@example.com"
        end
      end

      context "no strategy passed in" do
        let(:obfuscated_fields) { [:email] }

        it "shuffles contents" do
          expect(netto.email).to_not eq email
          expect(sorted_characters(netto.email)).to eq sorted_characters(email)
        end
      end

      def sorted_characters(str)
        str.split("").sort.join
      end
    end
  end
end
