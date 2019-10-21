class Parser
  TRANSACTION_RGX      = /\d{4}\/\d{1,2}\/\d{1,2} .+/.freeze
  TRANSACTION_DATE_RGX = /\d{4}\/\d{1,2}\/\d{1,2}/.freeze
  TRANSACTION_DESC_RGX = /[^\d{4}\/\d{1,2}\/\d{1,2}]+/.freeze
  ACCOUNT_DESC_RGX     = /[^\-?\$?\d+\.?\d+$]+/.freeze
  ACCOUNT_ACTION_RGX   = /\-?\$?\d+\.?\d?.+/.freeze
  ACCOUNT_AMOUNT_RGX   = /[\-.|\d]/.freeze
  ACCOUNT_CURRENCY_RGX = /[a-zA-z\$]+/.freeze
  COMMENT_RGX          = /[\;#%|*].+/.freeze
  INCLUDE_RGX          = /!include .+/.freeze
  LEDGER_FILE_RGX      = /[\w\/]+\.ledger$/.freeze
  DOLLAR_SIGN          = '$'.frezze
  USD_CURRENCY         = 'USD'.frezze

  attr_reader :parsed_file

  def initialize
    @parsed_file = []
  end

  def parse_ledger(file_path)
    file_size = file_size(file_path)
    tmp_transaction = {}
    tmp_account = {}
    tmp_amount_sum = 0.0
    tmp_currency = nil
    transaction_match = false

    File.open(file_path).each_with_index do |line, index|
      next if COMMENT_RGX.match(line)

      if line.start_with?('!include')
        new_file_path = line[LEDGER_FILE_RGX]
        @parsed_file |= parse_ledger(new_file_path)
      end

      if TRANSACTION_RGX.match(line)
        if transaction_match
            @parsed_file.push(tmp_transaction)
            tmp_amount_sum = 0.0
            tmp_transaction = { accounts: [] }
        end

        transaction_match = true
        tmp_transaction = { accounts: [] }
        tmp_transaction[:date] = line[TRANSACTION_DATE_RGX]
        tmp_transaction[:description] = line[TRANSACTION_DESC_RGX].strip
        next
      end

      if transaction_match
        if action = line[ACCOUNT_ACTION_RGX]
          amount = action.scan(ACCOUNT_AMOUNT_RGX).join
          currency = action[ACCOUNT_CURRENCY_RGX]
        end

        currency = USD_CURRENCY if currency.eql?(DOLLAR_SIGN)
        tmp_currency = currency if currency

        tmp_account[:description] = line[ACCOUNT_DESC_RGX].strip
        tmp_account[:amount] = amount ? amount.to_f : -tmp_amount_sum
        tmp_account[:currency] = tmp_currency
        tmp_transaction[:accounts].push(tmp_account)
        tmp_amount_sum += tmp_account[:amount]
        tmp_account = {}
      end

      @parsed_file.push(tmp_transaction) if (index == file_size - 1) && !tmp_transaction.empty?
    end

    @parsed_file
  end

  private

  def file_size(file_path)
    File.readlines(file_path).size
  end
end
