# Optional Flags

# --price-db FILE | Use FILE for retrieving stored commodity prices.
# --file FILE     | Read FILE as a ledger file.
# --sort VEXPR    | Sort a report using VEXPR.

require 'thor'
require 'colorize'
require_relative 'parser'

ACCOUNT_NESTED_RGX = /^\w+:/

class Ledger < Thor
  class_option :file, type: :string, default: 'index.ledger'

  desc "register", "The register command displays all the postings occurring in a single account, line by line."
  def register
    puts "register command"
  end

  desc "balance", "The balance command reports the current balance of all accounts. "
  def balance
    parser = Parser.new
    parser.parse_ledger(options[:file])

    transactions = {}
    transactions_sums = {}
    balances = {}

    parser.parsed_file.each do |transaction|
      transaction[:accounts].each do |account|
        if balances.include?(account[:currency])
          balances[account[:currency]] += account[:amount]
        else
          balances[account[:currency]] = account[:amount]
        end

        balances[account[:currency]] = balances[account[:currency]].round(2)

        if transactions_sums.include?(account[:description])
          transactions_sums[account[:description]] += account[:amount]
          transactions[account[:description]] = full_action(transactions_sums[account[:description]], account[:currency])
        else
          transactions_sums[account[:description]] = account[:amount]
          transactions[account[:description]] = full_action(account[:amount], account[:currency])
        end
      end
    end

    transactions.sort_by { |k, v| v }.reverse.each do |description, action|
      puts_format_line(action, description)
    end

    puts '--------------------'

    balances.each do |k, v|
      puts_format_line(full_action(v, k))
    end

  end

  desc "print", "The print command prints out ledger transactions in a textual format that can be parsed by Ledger."
  def print
    puts "print command"
  end

  private

  def full_action(amount, currency)
    "#{'%.2f' % amount} #{currency}"
  end

  def puts_format_line(action, description = nil)
    space = " " * (20 - action.size)

    if action.match(/-/)
      puts "#{space}#{action}  ".red + "#{description}".blue
    else
      puts "#{space}#{action}  " + "#{description}".blue
    end
  end

end

Ledger.start(ARGV)
