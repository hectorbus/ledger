require 'colorize'
require_relative '../parser'

class Balance
  USD_CURRENCY = 'USD'
  TWO_DECIMALS = '%.2f'
  EMPTY_SPACE  = ' '

  def initialize(options)
    @parser = Parser.new
    @parser.parse_ledger(options[:file])
    @balances = {}
    @transactions = {}
    @transactions_sums = {}
  end

  def calc(args)
    if args.any?
      @parser.parsed_file.each do |transaction|
        transaction[:accounts].each do |account|
          if account[:description][/#{args.join('|')}/i]
            calc_balance(account)
            calc_transactions(account)
          end
        end
      end
    else
      @parser.parsed_file.each do |transaction|
        transaction[:accounts].each do |account|
          calc_balance(account)
          calc_transactions(account)
        end
      end
    end

    @transactions.sort_by { |k, v| k }.each do |description, action|
      puts balance_line(action, description)
    end

    puts '--------------------'

    @balances.each do |k, v|
      puts balance_line(full_action(v, k))
    end
  end

  private

  def calc_transactions(account)
    if @transactions_sums.include?(account[:description])
      @transactions_sums[account[:description]] += account[:amount]
      @transactions[account[:description]] = full_action(@transactions_sums[account[:description]], account[:currency])
    else
      @transactions_sums[account[:description]] = account[:amount]
      @transactions[account[:description]] = full_action(account[:amount], account[:currency])
    end
  end

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

  def balance_line(action, description = nil)
    balance_text = EMPTY_SPACE * (20 - action.size) + action + EMPTY_SPACE
    balance_text = balance_text.red if action.match(/-/)
    blue_desc = "#{description}".blue

    balance_text + blue_desc
  end

end
