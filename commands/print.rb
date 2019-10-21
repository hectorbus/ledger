require_relative '../parser'

class Print
  USD_CURRENCY = 'USD'.freeze
  TWO_DECIMALS = '%.2f'.freeze
  EMPTY_SPACE  = ' '.freeze

  def initialize(options)
    @options = options
    @parser = Parser.new
    @parser.parse_ledger(@options[:file])
    @parsed_file = @parser.parsed_file
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
      tmp_accounts = ''

      @parsed_file.each do |transaction|
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
      @parsed_file.each do |transaction|
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
    if currency == USD_CURRENCY
      amount < 0 ? "-$#{TWO_DECIMALS % amount.to_s.delete('-')}" : "$#{TWO_DECIMALS % amount}"
    else
      "#{TWO_DECIMALS % amount} #{currency}"
    end
  end

  def print_title_line(date, description)
    "#{date}" + " #{description} "
  end

  def print_line(description, amount, currency)
    action = full_action(amount, currency)
    desc_space = EMPTY_SPACE * (38 - description.size)

    EMPTY_SPACE * 4 + description + desc_space + action
  end

end
