require 'date'
require 'colorize'
require_relative '../parser'

class Register
  USD_CURRENCY = 'USD'
  TWO_DECIMALS = '%.2f'
  EMPTY_SPACE  = ' '

  def initialize(options)
    @options = options
    @parser = Parser.new
    @parser.parse_ledger(@options[:file])
    @parsed_file = @parser.parsed_file
    @balances = {}
  end

  def calc(args)
    if @options[:sort]
      if @options[:sort] == 'date'
        @parsed_file = @parser.parsed_file.sort_by{ |h| Date.parse(h[@options[:sort].to_sym]) }
      else
        @parsed_file = @parser.parsed_file.sort_by{ |h| h[@options[:sort].to_sym] }
      end
    end

    if args.any?
      account_found = false

      @parsed_file.each do |transaction|
        transaction_text = register_title_line(transaction[:date], transaction[:description]) + "\n"

        transaction[:accounts].each do |account|
          if account[:description][/#{args.join('|')}/i]
            calc_balance(account)
            transaction_text += register_line(account[:description], account[:amount], @balances, account[:currency]) + "\n"
            account_found = true
          end
        end

        puts transaction_text if account_found
        account_found = false
      end
    else
      @parsed_file.each do |transaction|
        puts register_title_line(transaction[:date], transaction[:description])

        transaction[:accounts].each do |account|
          calc_balance(account)
          
          puts register_line(account[:description], account[:amount], @balances, account[:currency])
        end
      end
    end

    puts register_balance(@balances)
  end

  private

  def calc_balance(account)
    if @balances.include?(account[:currency])
      @balances[account[:currency]] += account[:amount]
    else
      @balances[account[:currency]] = account[:amount]
    end

    @balances[account[:currency]] = @balances[account[:currency]].round(2)
  end

  def full_action(amount, currency)
    if currency == USD_CURRENCY
      amount < 0 ? "-$#{TWO_DECIMALS % amount.to_s.delete('-')}" : "$#{TWO_DECIMALS % amount}"
    else
      "#{TWO_DECIMALS % amount} #{currency}"
    end
  end

  def register_title_line(date, description)
    "#{date.gsub('/', '-')}".light_black + " #{description} ".light_white
  end

  def register_line(description, amount, balances, currency)
    action = full_action(amount, currency)
    balance_text = register_balance_text(balances)
    blue_desc = "    #{description}".blue
    desc_space = EMPTY_SPACE * (50 - description.size) + EMPTY_SPACE * (20 - action.size)
    balance_space = EMPTY_SPACE * (20 - balance_text[/\w/].size)
    amount_full_action = "#{action}"
    amount_full_action = amount_full_action.red if amount < 0

    blue_desc + desc_space + amount_full_action + balance_space + balance_text
  end

  def register_balance(balances)
    balance_text = register_balance_text(balances)
    space = EMPTY_SPACE * 93
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
end
