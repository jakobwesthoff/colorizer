# Colorizer - A bash library for XML-like ansi coloring

**Colorizer** allows the easy usage of ANSI color coded output in shell scripts
using an XML-like syntax

## Usage

Simply call the `colorize` function instead of using `echo` supplying an
XML-like color definition

    colorize "Hey <red>attention</red>! the before seen is <light-red>red</light-red>"

**Colorizer** automatically injects the ANSI colorcodes needed to output the
given string in the correct color.

Nested tags are possible as well:

    colorize "<green>This is a <yellow>yellow colored</yellow> string inside a green one</green>"

Due to the XML-like nature of the used definition language `<` (less than) and
`>` (greater than) characters can no longer be used inside the provided string.
You need to escape them using their usual XML entity representation:

    colorize "<cyan>1</cyan> &lt; <purple>2</purple>"

Mismatched tags as well as missing start or end tags will be detected. In this
case an error message indicating the problem will be echoed back as well as an
exit with errorcode *42* will be issued.

### Options

Option | Type    | Description
------ | ------- | -----------
`-n`   | Boolean | Suppress the newline echoed by default
`-p`   | Boolean | Escape ANSI colorcodes for prompt usage
`-s`   | Boolean | Strip XML color tags rather than injecting ANSI

### Examples

**Colorizer** uses the `echo -e` command to output the formatted information.
Therefore a newline is automatically echoed at the end of the string. If you do
not want to output this newline just supply the `-n` option to `colorize`. In
this case `echo -en` is used for output to suppress the newline:

    colorize -n "<blue>Question:</blue> Do you think this library rocks? [Y/n]"

To use **Colorizer** with prompts (e.g. `$PS1`), ANSI colorcodes should be
escaped with `\[` and `\]`. This is accomplished with the `-p` option:

    PS1=$(colorize -p "<yellow>\@ \u@\h:\W</yellow> $ ")

It's common to use a string for both terminal ouput and a log file, while the
log may be viewed elsewhere without ANSI color support. The option `-s` simply
strips XML tags without including ANSI colors.

    LOG_STRING="<magenta>$TIME</magenta>: <cyan>$EVENT</cyan>"
    # Redirect to log file without colors
    colorize -s $LOG_STRING >> myprogram.log
    # Send to stdout with colors
    colorize $LOG_STRING

### Aliases

As *colorize* and *colourise* is differently spelled in american and british
english an alias is defined for the `colorize` function. Therefore you may
substitute it with the `colourise` command without thinking about it.

## Loading the Library

Before you can use the library you need to load it into your bash script.
A simple call to the `source` function will enable you to do this:

    source "folder/to/Colorizer/Library/colorizer.sh"

After that the `colorize` function is available and works as expected.

If your shell does neither set `$BASH_SOURCE` nor `$0` in the sourced file, you
have to manually define the variable `COLORIZE_SH_SOURCE_DIR` to the directory
containing the `colorize.sh` file.

## Available Color-Tags

Currently all *16* default ANSI terminal colors are supported. Maybe support
for the extended 256 colors modern terminals are capable of displaying will be
added in the future.

Currently the following tags are supported:

Color Tag                                      | Generated ANSI Code
---------------------------------------------- | -------------------
&lt;**red**&gt;…&lt;/red&gt;                   | \033[0;31m
&lt;**green**&gt;…&lt;/green&gt;               | \033[0;32m
&lt;**yellow**&gt;…&lt;/yellow&gt;             | \033[0;33m
&lt;**blue**&gt;…&lt;/blue&gt;                 | \033[0;34m
&lt;**purple**&gt;…&lt;/purple&gt;             | \033[0;35m
&lt;**cyan**&gt;…&lt;/cyan&gt;                 | \033[0;36m
&lt;**light-red**&gt;…&lt;/light-red&gt;       | \033[1;31m
&lt;**light-green**&gt;…&lt;/light-green&gt;   | \033[1;32m
&lt;**light-yellow**&gt;…&lt;/light-yellow&gt; | \033[1;33m
&lt;**light-blue**&gt;…&lt;/light-blue&gt;     | \033[1;34m
&lt;**light-purple**&gt;…&lt;/light-purple&gt; | \033[1;35m
&lt;**light-cyan**&gt;…&lt;/light-cyan&gt;     | \033[1;36m
&lt;**gray**&gt;…&lt;/gray&gt;                 | \033[1;30m
&lt;**light-gray**&gt;…&lt;/light-gray&gt;     | \033[0;37m
&lt;**white**&gt;…&lt;/white&gt;               | \033[1;37m
&lt;**black**&gt;…&lt;/black&gt;               | \033[0;30m
&lt;**none**&gt;…&lt;/none&gt;                 | \033[0m

## Limitations

Currently this library has only been tested with the
[Bash](http://www.gnu.org/software/bash/) (>3.x),
[ZSH](http://zsh.sourceforge.net/) shell (>5.x) and
[busybox](http://www.busybox.net/) ash. The code should run in every POSIX
compatible shell as well, but I didn't have the time to test those yet.

**Colorizer** uses a lot of quite sophisticated variable expansion features, to
do all the XML-tag extraction and parsing using only shell builtins to provide
a fast and nice user experience. Therefore making the library compatible
with less powerful shells may be a difficult task. However a compatibility
layer exists, which may allow implementation of complex tasks for different shells.

Background color setting is currently not supported. I simply don't have real
demand for that in most of my scripts. If you want this feature just drop me
a line, maybe with an example how the syntax for this could look. I will see
what I can do then. :)

## How you can help

If you have got some time and are using currently untested shells, I would love
some feedback about the compatibility of this library with your environment.

If you are interested in porting this library over to another shell
environment, any pull request with compatibility updates will be great. Error
output and information about your shell may help me as well.
