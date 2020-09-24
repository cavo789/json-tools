# JSON-TOOLS

![Banner](./banner.svg)

Work on top of the work of [Viacheslav Poturaev](https://github.com/vearutop) - [JSON-diff CLI tool](https://github.com/swaggest/json-cli) :clap: :clap:

The idea of these scripts are simple: make easier to work with `.json` files.

<!-- concat-md::toc -->

## How to install

Download a copy of this repository and make sure to add the target folder to your `PATH` environment variable. So, whatever the active folder, you only have to indicate the name of the script you want to run e.g. `json-diff` for it to be executed.

After the download, please run `composer install` (yes, you need [composer](https://getcomposer.org/) if you don't have it already) to install dependencies.

## Scripts

### json-diff

You've a file called f.i. `settings.json` with a big number of settings and their values and in a second project, you have the same file but probably not with the same values.

How to compare the two files and only display values in the second file that have been updated i.e. different in the first `settings.json` file?

In my case, my need is slightly different: one of my applications is generic and totally driven from a file named `hooks.json` (say `/git_hooks/hooks.json`).

When this file is present in another folder (say `/another_application/hooks.json`), if I start my `git_hooks` program, this is the file that will be used.  If the `hooks.json` file isn't present in that folder, the global `/git_hooks/hooks.json` file will be used.

So `/another_application/hooks.json` is just a copy of `/git_hooks/hooks.json` with, probably, adjusted settings.

Having dozens of applications, it becomes difficult to know what changes would have been made in each file compared to the global file.

The `json-diff` script comes to fill this need.

The output will be something like:

```json
{
    "version":  "1.0.1",
    "tasks":  {
        "xmlprettier":  {
            "enabled":  0
        }
    }
}
```

Only updated keys will be displayed.

If the `/git_hooks/hooks.json` file contains 1,000 lines and `/another_application/hooks.json` has adapted only two values, then only these values are displayed, just like illustrated above.

```bash
json-diff -help
```

```txt
JSON CLI tool - Hight differences in the second file

Usage: json-diff [-help] <original.json> <compared.json>

-help           Show this screen

<original.json> Name of the original JSON file, the one used as the template

<compared.json> Name of the 'Compared with' file, the one in which changes will be inspected

Some examples
-------------

json-diff original.json updated.json  Show the list of keys from updated.json that have been modified i.e. whose value is different in the original file.

Run json-diff samples\original.json samples\updated.json for a real example
```

#### Some command line examples

```bash
json-diff samples\original.json samples\updated.json
```

Take a look to the `/samples/original.json` and `/samples/updated.json` files to see how it works.
