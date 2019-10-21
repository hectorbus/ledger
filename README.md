# Ledger

**Simple implementation of the [ledger cli](https://www.ledger-cli.org/3.0/doc/ledger3.html) in Ruby**

Requirements
------------
+ Ruby: 2.6.0
+ [Thor](https://github.com/erikhuda/thor) gem
+ [Colorize](https://github.com/fazibear/colorize) gem

Usage
-----
Make sure that you have all the requirements installed and clone the repository. In command line, navigate to the repository and run the next line with a specific command and it's options.
```
$ ruby ledger.rb [COMMAND] [OPTIONS]
```
Don't forget to add transactions to your ledger file, otherwise, Ledger will not be able to calculate the request. You can look at some examples in the folder `/records`.

### Usage examples

Shows the current balance of `records/Income.ledger`:
```
$ ruby ledger.rb balance --file records/Income.ledger
```
Displays all the postings occurring in a single account, line by line, ordered by date.
```
$ ruby ledger.rb register --sort date
```
Prints out ledger transactions with the argument `bank`, ordered by description
```
$ ruby ledger.rb print bank --sort description
```

Commands
--------
* `help [COMMAND]` —  Describe available commands or one specific command
* `bal`, `balance [ARGS]` —  Reports the current balance of all accounts. Optionally, can receive arguments to filter the transactions.
* `reg`, `register [ARGS]` —  Displays all the postings occurring in a single account, line by line. Optionally, can receive arguments to filter the postings.
* `print [ARGS]` —  Prints out ledger transactions in a textual format ruby that can be parsed by Ledger. Optionally, can receive arguments to filter the transactions.

Options
--------
* `-f`,`[--file FILE]` —  Read FILE as a ledger file. Default: index.ledger
* `-s`,`[--sort SORT]` —  Sort a report. Available SORT options: [date, description]
* `[--price-db FILE]` —  Specify the location of the price entry data FILE.
