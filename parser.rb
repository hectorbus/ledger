class Parser
  TRANSACTION_RGX      = /\d{4}\/\d{1,2}\/\d{1,2} .+/
  TRANSACTION_DATE_RGX = /\d{4}\/\d{1,2}\/\d{1,2}/
  TRANSACTION_DESC_RGX = /[^\d{4}\/\d{1,2}\/\d{1,2}]+/
  ACCOUNT_DESC_RGX     = /[^\-?\$?\d+\.?\d+$]+/
  ACCOUNT_ACTION_RGX   = /\-?\$?\d+\.?\d?.+/
  ACCOUNT_AMOUNT_RGX   = /[\-.|\d]/
  ACCOUNT_CURRENCY_RGX = /[a-zA-z]+/
  COMMENT_RGX          = /[\;#%|*].+/
  INCLUDE_RGX          = /!include .+/
  LEDGER_FILE_RGX      = /\w+\.ledger$/

  def initialize
    @parsed_file = []
  end

  def parse_ledger(file_path)
    relative_file_path = relative_file_path(file_path)
    file_lenght = File.readlines(relative_file_path).size
    tmp_transaction = {}
    tmp_account = {}
    tmp_amount_sum = 0.0
    tmp_currency = nil
    transaction_match = false

    File.open(relative_file_path).each_with_index do |line, index|
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
        action = line[ACCOUNT_ACTION_RGX]
        amount = action ? action.scan(ACCOUNT_AMOUNT_RGX).join : nil
        currency = action ? action[ACCOUNT_CURRENCY_RGX] : "USD"

        tmp_account[:description] = line[ACCOUNT_DESC_RGX].strip
        tmp_account[:amount] = amount ? amount.to_f : -tmp_amount_sum
        tmp_account[:currency] = currency ? currency : 'USD'
        tmp_transaction[:accounts].push(tmp_account)
        tmp_amount_sum += tmp_account[:amount]
        tmp_account = {}
      end

      if index == file_lenght - 1
        @parsed_file.push(tmp_transaction) unless tmp_transaction.empty?
      end
    end

    @parsed_file
  end

  private

  def relative_file_path(file_path)
    "records/#{file_path}"
  end
end
