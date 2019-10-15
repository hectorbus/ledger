require 'thor'

class Ledger < Thor
  desc "register", "The register command displays all the postings occurring in a single account, line by line."
  def register
    puts "register command"
  end

  desc "balance", "The balance command reports the current balance of all accounts. "
  def balance
    puts "balance command"
  end

  desc "print", "The print command prints out ledger transactions in a textual format that can be parsed by Ledger."
  def print
    puts "print command"
  end
end

Ledger.start(ARGV)
