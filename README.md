# Ledger

**Simple implementation of the [ledger cli](https://www.ledger-cli.org/3.0/doc/ledger3.html) in Ruby**

Requirements:
+ Ruby: 2.6.0
+ [Thor](https://github.com/erikhuda/thor) gem
+ [Colorize](https://github.com/fazibear/colorize) gem

Run with:
```
$ ruby ledger.rb
```

Available commands:
```
$ ruby ledger.rb -h
Commands:
  ruby ledger.rb balance         # The balance command reports the current balance of all accounts.
  ruby ledger.rb help [COMMAND]  # Describe available commands or one specific command
  ruby ledger.rb print           # The print command prints out ledger transactions in a textual format that can be parsed by Led...
  ruby ledger.rb register        # The register command displays all the postings occurring in a single account, line by line.

Options:
  [--file=FILE]
                 # Default: index.ledger
```
