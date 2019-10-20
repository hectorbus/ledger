# Optional Flags

# --price-db FILE | Use FILE for retrieving stored commodity prices.
# --file FILE     | Read FILE as a ledger file.
# --sort VEXPR    | Sort a report using VEXPR.

require 'thor'
require 'date'
require 'colorize'
require_relative 'parser'

class Ledger < Thor
  class_option :file, type: :string, default: 'index.ledger'
  class_option :sort, type: :string
  class_option :"price-db", type: :string

  def initialize(*args)
    super
    @parser = Parser.new
    @parser.parse_ledger(options[:file])
    @balances = {}
  end

  desc "register", "The register command displays all the postings occurring in a single account, line by line."
  def register(*args)
    set_price_db_file(options[:'price-db']) if options[:'price-db']

    parsed_file = @parser.parsed_file
    parsed_file = @parser.parsed_file.sort_by{ |h| h[options[:sort].to_sym] } if options[:sort]
    parsed_file = @parser.parsed_file.sort_by{ |h| Date.parse(h[options[:sort].to_sym]) } if options[:sort] == 'date'

    if args.any?
      account_found = false

      parsed_file.each do |transaction|
        transaction_text = register_title_line(transaction[:date], transaction[:description]) + "\n"

        transaction[:accounts].each do |account|
          if account[:description][/#{args.join('|')}/i]
            if @balances.include?(account[:currency])
              @balances[account[:currency]] += account[:amount]
            else
              @balances[account[:currency]] = account[:amount]
            end

            @balances[account[:currency]] = @balances[account[:currency]].round(2)
            transaction_text += register_line(account[:description], account[:amount], @balances, account[:currency]) + "\n"
            account_found = true
          end
        end

        puts transaction_text if account_found
        account_found = false
      end
    else
      parsed_file.each do |transaction|
        puts register_title_line(transaction[:date], transaction[:description])

        transaction[:accounts].each do |account|
          if @balances.include?(account[:currency])
            @balances[account[:currency]] += account[:amount]
          else
            @balances[account[:currency]] = account[:amount]
          end

          @balances[account[:currency]] = @balances[account[:currency]].round(2)
          puts register_line(account[:description], account[:amount], @balances, account[:currency])
        end
      end
    end

    puts register_balance(@balances)
  end

  desc "balance", "The balance command reports the current balance of all accounts. "
  def balance(*args)
    set_price_db_file(options[:'price-db']) if options[:'price-db']

    transactions = {}
    transactions_sums = {}

    if args.any?
      account_found = false

      @parser.parsed_file.each do |transaction|
        transaction[:accounts].each do |account|
          if account[:description][/#{args.join('|')}/i]
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
      end
    else
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
    end

    transactions.sort_by { |k, v| v }.reverse.each do |description, action|
      puts balance_line(action, description)
    end

    puts '--------------------'

    @balances.each do |k, v|
      puts balance_line(full_action(v, k))
    end
  end

  desc "print", "The print command prints out ledger transactions in a textual format that can be parsed by Ledger."
  def print(*args)
    set_price_db_file(options[:'price-db']) if options[:'price-db']

    parsed_file = @parser.parsed_file
    parsed_file = @parser.parsed_file.sort_by{ |h| h[options[:sort].to_sym] } if options[:sort]
    parsed_file = @parser.parsed_file.sort_by{ |h| Date.parse(h[options[:sort].to_sym]) } if options[:sort] == 'date'

    if args.any?
      account_found = false
      tmp_accounts = ''

      parsed_file.each do |transaction|
        transaction_text = print_title_line(transaction[:date], transaction[:description]) + "\n"

        transaction[:accounts].each do |account|
          account_found = true if account[:description][/#{args.join('|')}/i]
          tmp_accounts += print_line(account[:description], account[:amount], account[:currency]) + "\n"
        end

        puts transaction_text + tmp_accounts + "\n" if account_found
        account_found = false
        tmp_accounts = ''
      end
    else
      parsed_file.each do |transaction|
        puts print_title_line(transaction[:date], transaction[:description])

        transaction[:accounts].each do |account|
          puts print_line(account[:description], account[:amount], account[:currency])
        end

        puts "\n"
      end
    end

  end

  private

  def full_action(amount, currency)
    if currency == 'USD'
      amount < 0 ? "-$#{'%.2f' % amount.to_s.delete('-')}" : "$#{'%.2f' % amount}"
    else
      "#{'%.2f' % amount} #{currency}"
    end
  end

  def balance_line(action, description = nil)
    balance_text = " " * (20 - action.size) + action + ' '
    balance_text = balance_text.red if action.match(/-/)
    blue_desc = "#{description}".blue

    balance_text + blue_desc
  end

  def register_title_line(date, description)
    "#{date.gsub('/', '-')}".light_black + " #{description} ".light_white
  end

  def register_line(description, amount, balances, currency)
    action = full_action(amount, currency)
    balance_text = register_balance_text(balances)
    blue_desc = "    #{description}".blue
    desc_space = ' ' * (50 - description.size) + ' ' * (20 - action.size)
    balance_space = ' ' * (20 - balance_text[/\w/].size)
    amount_full_action = "#{action}"
    amount_full_action = amount_full_action.red if amount < 0

    blue_desc + desc_space + amount_full_action + balance_space + balance_text
  end

  def register_balance(balances)
    balance_text = register_balance_text(balances)
    space = ' ' * 93
    dashes = '-' * 20

    space + dashes + "\n" + space + balance_text
  end

  def register_balance_text(balances)
    balance_text = ''

    balances.each_with_index do |balance, index|
      text = "#{full_action(balance.last, balance.first)}"
      text = text.red if balance.last < 0
      text = text + ', ' unless balances.size - 1 == index

      balance_text += text
    end

    balance_text
  end

  def print_title_line(date, description)
    "#{date}" + " #{description} "
  end

  def print_line(description, amount, currency)
    action = full_action(amount, currency)
    desc_space = ' ' * (38 - description.size)

    "    " + description + desc_space + action
  end

  def set_price_db_file(path)
    File.open("config.ledger", "w") { |file| file.puts "price_db_file: #{path}"}
  end

  def get_price_db_file
    File.open("config.ledger").each do |line|
      return line[/[^price_db_file:].+$/].strip
    end
  end

  def find_price_db_price(file_path, currency)
    currency_market = nil

    File.open(file_path).each do |line|
      line_currency = line.scan(/[a-zA-z]+/).last

      if line_currency == currency
        currency_market = line[/\$.*/].delete('$').to_f.round(2)
      end
    end

    currency_market
  end

end

Ledger.start(ARGV)
