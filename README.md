# Coral Backup

Coral Backup creates incremental backups of files that can be restored at a later date.

![run](https://cloud.githubusercontent.com/assets/1025461/8147090/2d8be3bc-1299-11e5-8c46-50127cf74246.gif)

## Installation

```
$ gem install coral_backup
```

## Usage
### Commands

* `coral add <ACTION>`: Add a new backup action
* `coral delete <ACTION>`: Delete the backup action
* `coral help [COMMAND]`: Describe available commands or one specific command
* `coral list`: Show all backup actions
* `coral run <ACTION>`: Run the backup action
* `coral info <ACTION>`: Show information about the backup action
* `coral version`: Print the version

### Options

* `-d`, `--dry-run`: Show what would have been backed up, but do not back them up

### Demo

![add](https://cloud.githubusercontent.com/assets/1025461/8147087/22e5ba1e-1299-11e5-91b2-1d39add9febb.gif)

![info](https://cloud.githubusercontent.com/assets/1025461/8147088/2a55297e-1299-11e5-8a2d-222902419c6c.gif)

## Dependencies

* rsync 3.X.X binary

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec coral` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Tatzyr/coral_backup.
