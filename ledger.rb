# Optional Flags

# --price-db FILE | Use FILE for retrieving stored commodity prices.
# --file FILE     | Read FILE as a ledger file.
# --sort VEXPR    | Sort a report using VEXPR.

require 'thor'
require_relative 'commands/balance'
require_relative 'commands/register'
require_relative 'commands/print'

class Ledger < Thor
  CONFIG_FILE    = 'config.ledger'
  REGISTER_ALIAS = 'reg'
  BALANCE_ALIAS  = 'bal'
  DOLLAR_SIGN    = '$'

  class_option :file, type: :string, aliases:'-f', default: 'index.ledger'
  class_option :sort, type: :string, aliases:'-s'
  class_option :"price-db", type: :string

  def initialize(*args)
    super
  end

  desc "register", "The register command displays all the postings occurring in a single account, line by line."
  def register(*args)
    set_price_db_file(options[:'price-db']) if options[:'price-db']

    register = Register.new(options)
    register.calc(args)
  end

  desc "balance", "The balance command reports the current balance of all accounts. "
  def balance(*args)
    set_price_db_file(options[:'price-db']) if options[:'price-db']

    balance = Balance.new(options)
    balance.calc(args)
  end

  desc "print", "The print command prints out ledger transactions in a textual format that can be parsed by Ledger."
  def print(*args)
    set_price_db_file(options[:'price-db']) if options[:'price-db']

    print = Print.new(options)
    print.calc(args)
  end

  map REGISTER_ALIAS => :register
  map BALANCE_ALIAS => :balance

  private

  def set_price_db_file(path)
    File.open(CONFIG_FILE, "w") { |file| file.puts "price_db_file: #{path}"}
  end

  def get_price_db_file
    File.open(CONFIG_FILE).each do |line|
      return line[/[^price_db_file:].+$/].strip
    end
  end

  def find_price_db_price(file_path, currency)
    currency_market = nil

    File.open(file_path).each do |line|
      line_currency = line.scan(/[a-zA-z]+/).last

      if line_currency == currency
        currency_market = line[/\$.*/].delete(DOLLAR_SIGN).to_f.round(2)
      end
    end

    currency_market
  end

end

Ledger.start(ARGV)
