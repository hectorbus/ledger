# Optional Flags

# --price-db FILE | Use FILE for retrieving stored commodity prices.
# --file FILE     | Read FILE as a ledger file.
# --sort VEXPR    | Sort a report using VEXPR.

require 'thor'
require 'colorize'
require_relative 'parser'

class Ledger < Thor
  class_option :file, type: :string, default: 'index.ledger'

  def initialize(*args)
    super
    @parser = Parser.new
    @parser.parse_ledger(options[:file])
    @balances = {}
  end

  desc "register", "The register command displays all the postings occurring in a single account, line by line."
  def register
    @parser.parsed_file.each do |transaction|
      register_title_line(transaction[:date], transaction[:description])

      transaction[:accounts].each do |account|
        if @balances.include?(account[:currency])
          @balances[account[:currency]] += account[:amount]
        else
          @balances[account[:currency]] = account[:amount]
        end

        @balances[account[:currency]] = @balances[account[:currency]].round(2)
        register_line(account[:description], account[:amount], @balances, account[:currency])
      end
    end

    register_balance(@balances)
  end

  desc "balance", "The balance command reports the current balance of all accounts. "
  def balance
    transactions = {}
    transactions_sums = {}

    @parser.parsed_file.each do |transaction|
      transaction[:accounts].each do |account|
        if @balances.include?(account[:currency])
          @balances[account[:currency]] += account[:amount]
        else
          @balances[account[:currency]] = account[:amount]
        end

        @balances[account[:currency]] = @balances[account[:currency]].round(2)

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
      balance_line(action, description)
    end

    puts '--------------------'

    @balances.each do |k, v|
      balance_line(full_action(v, k))
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

  def balance_line(action, description = nil)
    action = " " * (20 - action.size) + action + ' '
    action = action.red if action.match(/-/)
    blue_desc = "#{description}".blue

    puts action + blue_desc
  end

  def register_title_line(date, description)
    puts "#{date}".light_black + " #{description} ".light_white
  end

  def register_line(description, amount, balances, currency)
    action = full_action(amount, currency)
    balance_text = register_balance_text(balances)
    blue_desc = "    #{description}".blue
    desc_space = ' ' * (50 - description.size) + ' ' * (20 - action.size)
    balance_space = ' ' * (30 - balance_text[/\w/].size)
    amount_full_action = "#{action}"
    amount_full_action = amount_full_action.red if amount < 0

    puts blue_desc + desc_space + amount_full_action + balance_space + balance_text
  end

  def register_balance(balances)
    balance_text = register_balance_text(balances)

    puts ' ' * 103 + '-' * 23
    puts ' ' * 103 + balance_text
  end

  def register_balance_text(balances)
    balance_text = ''

    balances.each_with_index do |b, i|
      text = "#{full_action(b.last, b.first)}"
      text = text.red if b.last < 0
      text = text + ', ' unless balances.size - 1 == i

      balance_text += text
    end

    balance_text
  end

end

Ledger.start(ARGV)
