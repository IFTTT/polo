require 'spec_helper'

describe Polo::Configuration do

  describe 'on_duplicate' do
    it 'defaults to nothing' do
      expect(Polo.defaults.on_duplicate_strategy).to be nil
    end

    it 'accepts custom strategies' do
      Polo.configure do
        on_duplicate(:ignore)
      end

      defaults = Polo.defaults
      expect(defaults.on_duplicate_strategy).to eq(:ignore)
    end
  end

  describe 'obfuscate' do
    it 'defaults to an empty list' do
      expect(Polo.defaults.blacklist).to be_empty
    end

    it 'allows for the user to define fields to blacklist' do
      Polo.configure do
        obfuscate(:email, :password)
      end

      defaults = Polo.defaults
      expect(defaults.blacklist).to eq([:email, :password])
    end

    it 'allows for the user to define fields with strategies in blacklist' do
      Polo.configure do
        email_strategy = lambda {|e| "#{e.split("@")[0]}_test@example.com" }
        credit_card_strategy = lambda {|_| "4111111111111111"}
        obfuscate({email: email_strategy, credit_card: credit_card_strategy})
      end

      defaults = Polo.defaults
      expect(defaults.blacklist.first[:email].call("a@b.com")).to eq("a_test@example.com")
    end
  end
end
