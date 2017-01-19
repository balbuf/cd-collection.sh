# cd Collection

Easily manage and access the directories you `cd` into most often. _cd Collection_
allows you to "bookmark" any local directory with an alias of your choosing to
quickly jump to that location or use it as a jumping point to access relative
subdirectories or parent directories. Aliases are unique, but a directory may
have more than one alias.

## Commands

### add

Add a new alias for the current directory without overwriting an existing alias.
Returns an error if the alias already exists, so it is safe from affecting other aliases.

> `cdc add <alias-name>`

To create a new alias, first navigate to the desired target location:

```sh
$ cd ~/Documents
$ cdc add docs
```

Alias names can contain any characters that an actual directory name can contain, i.e.
pretty much anything besides a forward slash (`/`) or null character.

### get

Get the path of a given alias. Similar to (and using) `pwd`, this command will print the
full target target path for the alias.

> `cdc get <alias-name>[/<relative-path>]`

The `get` commmand can be used with an alias alone:

```sh
$ cdc get logs
> /var/logs
```

or with an additional relative path along with the alias:

```sh
$ cdc get logs/apache2
> /var/logs/apache2
```

If `cdc` detects that it is executed _outside_ of an interactive shell, the `get` command
is implied in the absense of an explicit command:

```sh
$ echo "The path for the 'logs' alias is '$(cdc logs)'"
> The path for the 'logs' alias is '/var/logs'

$ tail -f $(cdc logs/apache2)/error_log
```

To avoid collisions with `cdc` command names, the alias name can be preceded by `--`:

```sh
$ echo "Help files are located at $(cdc -- help)"
> Help files are located at /Users/me/Documents/help-files
```

### go

Change current directory to the path of the given alias.

> `cdc go <alias-name>[/<relative-path>]`

As with `get`, `go` can act upon a plain alias:

```sh
$ cdc go home
```

or with a relative path under or above the alias target location:

```sh
$ cdc go home/..
```

If `cdc` detects that it is executed _inside_ of an interactive shell, the `go` command
is implied in the absense of an explicit command. This is the most common use case:

```sh
$ cdc repos
```

### help

Display a brief help message covering basic usage and a list of commands.

> cdc help

```sh
$ `cdc help`
```

The same help message is displayed if `cdc` is executed with no arguments.

### ls (list)

See a list of some or all existing aliases.

> cdc ls [<path>]

### set

Add or overwrite an existing alias pointing to the current directory. Unlike `add`,
this command will forcefully replace an existing alias with the same name.

> `cdc set <alias-name>`

Navigate to the directory of your choosing to set an alias pointing there:

```sh
$ cd ~/.ssh
$ cdc set ssh
```

show   Show any aliases pointing to the current directory

### rm (remove)

Attempt to remove an existing alias. Returns an error if the alias is not valid
or if it cannot be removed.

> `cdc rm <alias-name>`
> `cdc remove <alias-name>`

