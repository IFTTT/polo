# Support old BigDecimal constructor for sqlite3 (among others?)
class BigDecimal
  def self.new(*args)
    BigDecimal(*args)
  end
end
