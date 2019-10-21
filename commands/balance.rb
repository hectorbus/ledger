require 'colorize'
require_relative '../parser'

class Balance
  ACCOUNT_CURRENCY_RGX = /[a-zA-z\$]+/.freeze
  ACCOUNT_AMOUNT_RGX   = /[\-.|\d]/.freeze
  FATHER_ACCOUNT_RGX   = /^\w+/.freeze
  USD_CURRENCY         = 'USD'.freeze
  TWO_DECIMALS         = '%.2f'.freeze
  EMPTY_SPACE          = ' '.freeze

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

    generate_nested_accounts()
    prev_description = ''

    @transactions.sort_by { |k, v| k }.each_with_index do |transaction, index|
      description = transaction.first
      action = transaction.last

      if index != 0 && (prev_description[FATHER_ACCOUNT_RGX] == description[FATHER_ACCOUNT_RGX])
        puts balance_line(action, description, true)
      else
        puts balance_line(action, description)
      end

      prev_description = description
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
    else
      @transactions_sums[account[:description]] = account[:amount]
    end

    @transactions[account[:description]] = full_action(@transactions_sums[account[:description]], account[:currency])
  end

  def calc_balance(account)
    if @balances.include?(account[:currency])
      @balances[account[:currency]] += account[:amount]
    else
      @balances[account[:currency]] = account[:amount]
    end

    @balances[account[:currency]] = @balances[account[:currency]].round(2)
  end

  def generate_nested_accounts()
    sorted_transactions = @transactions.sort_by { |k, v| k }
    prev_description = sorted_transactions.first.first
    prev_action = sorted_transactions.first.last
    new_accounts = {}

    sorted_transactions.each_with_index do |transaction, index|
      if index != 0
        description = transaction.first
        action = transaction.last

        if description[/^\w+/] == prev_description[/^\w+/]
          if new_accounts[description[/^\w+/]]
            new_accounts[description[/^\w+/]].push(prev_action)
          else
            new_accounts[description[/^\w+/]] = [action, prev_action]
          end
        end

        prev_description = description
        prev_action = action
      end
    end

    new_accounts.each do |account, amounts|
      balances = {}
      new_accounts_text = []

      amounts.each do |amount|
        currency = amount.scan(ACCOUNT_CURRENCY_RGX).join
        currency = USD_CURRENCY if currency.eql?("$")
        amount_n = amount.scan(ACCOUNT_AMOUNT_RGX).join

        if balances[currency]
          balances[currency] += amount_n.to_f.round(2)
        else
          balances[currency] = amount_n.to_f.round(2)
        end
      end

      new_accounts[account] = balances
    end

    new_accounts.each do |account|
      new_accounts_text = []

      account.last.each do |action|
        new_accounts_text.push(full_action(action.last, action.first))
      end

      @transactions[account.first] = new_accounts_text.join(', ')
    end
  end

  def full_action(amount, currency)
    if currency == USD_CURRENCY
      amount < 0 ? "-$#{TWO_DECIMALS % amount.to_s.delete('-')}" : "$#{TWO_DECIMALS % amount}"
    else
      "#{TWO_DECIMALS % amount} #{currency}"
    end
  end

  def balance_line(action, description = nil, tab = nil)
    blue_desc = "#{description}"
    action.size < 20 ? empty_space = EMPTY_SPACE * (20 - action.size) : empty_space = ''
    balance_text = empty_space + action + EMPTY_SPACE * 2
    balance_text = balance_text.red if action.match(/-/)

    if tab
      blue_desc = ("  " + blue_desc.scan(/(?<=:).*/).join)
    end

    balance_text + blue_desc.blue
  end

end
