# Colorizer - A bash library for XML-like ansi coloring

**Colorizer** allows the easy usage of ANSI color coded output in bash scripts
using an XML-like syntax

## Usage and Examples

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

**Colorizer** used the `echo -e` command to output the formatted information.
Therefore a newline is automatically echoed at the end of the string. If you do
not want to output this newline just supply the `-n` option to `colorize`. In
this case `echo -en` is used for output to suppress the newline:

    colorize -n "<blue>Question:</blue> Do you think this library rocks? [Y/n]"

Mismatched tags as well as missing start or end tags will be detected. In this
case an error message indicating the problem will be echoed back as well as an
exit with errorcode *42* will be issued.

## Loading the Library

Before you can use the library you need to load it into your bash script.
A simple call to the `source` function will enable you to do this:

    source "folder/to/Colorizer/lib/colorizer.sh"

After that the `colorize` function is available and works as expected.

## Available Color-Tags

Currently all *16* default ANSI terminal colors are supported. Maybe support
for the extended 256 colors modern terminals are capable of displaying will be
added in the future.

Currently the following tags are supported:

<table>
    <tr>
        <th>Color Tag</th><th>Generated ANSI Code</th>
    </tr>
    <tr>
        <td>&lt;red&gt;…&lt;/red&gt;</td><td>\033[0;31m</td>
    </tr>
        <td>&lt;green&gt;…&lt;/green&gt;</td><td>\033[0;32m</td>
    </tr>
        <td>&lt;yellow&gt;…&lt;/yellow&gt;</td><td>\033[0;33m</td>
    </tr>
        <td>&lt;blue&gt;…&lt;/blue&gt;</td><td>\033[0;34m</td>
    </tr>
        <td>&lt;purple&gt;…&lt;/purple&gt;</td><td>\033[0;35m</td>
    </tr>
        <td>&lt;cyan&gt;…&lt;/cyan&gt;</td><td>\033[0;36m</td>
    </tr>
        <td>&lt;light-red&gt;…&lt;/light-red&gt;</td><td>\033[1;31m</td>
    </tr>
        <td>&lt;light-green&gt;…&lt;/light-green&gt;</td><td>\033[1;32m</td>
    </tr>
        <td>&lt;light-yellow&gt;…&lt;/light-yellow&gt;</td><td>\033[1;33m</td>
    </tr>
        <td>&lt;light-blue&gt;…&lt;/light-blue&gt;</td><td>\033[1;34m</td>
    </tr>
        <td>&lt;light-purple&gt;…&lt;/light-purple&gt;</td><td>\033[1;35m</td>
    </tr>
        <td>&lt;light-cyan&gt;…&lt;/light-cyan&gt;</td><td>\033[1;36m</td>
    </tr>
        <td>&lt;gray&gt;…&lt;/gray&gt;</td><td>\033[1;30m</td>
    </tr>
        <td>&lt;light-gray&gt;…&lt;/light-gray&gt;</td><td>\033[0;37m</td>
    </tr>
        <td>&lt;white&gt;…&lt;/white&gt;</td><td>\033[1;37m</td>
    </tr>
        <td>&lt;black&gt;…&lt;/black&gt;</td><td>\033[0;30m</td>
    </tr>
        <td>&lt;none&gt;…&lt;/none&gt;</td><td>\033[0m</td>
    </tr>
</table>

## Limitations

Currently this library has only been tested with the
[Bash](http://www.gnu.org/software/bash/) shell in versions greater than 3.x.
Maybe other modern shells will work as well, but I didn't have the time to test
those yet.

**Colorizer** uses a lot of quite sophisticated variable expansion features, to
do all the XML-tag extraction and parsing using only shell builtins to provide
a fast and nice user experience. Therefore making the library compatible with
less powerful shells like for example *ash* from the [busybox](http://busybox.net) 
project may be a difficult task.

Background color setting is currently not supported as well. I simply don't
have a real demand for that in most of my scripts. If you want this feature
just drop me a line, maybe with an example how the syntax for this could look.
I will see what I can do then. :)

## How you can help

If you have got some time and are using another shell than bash, I would love
some feedback about the compatibility of this library with your shell.

If you are interested in porting this library over to another shell, any pull
request with compatibility updates as well as error output and information
about your shell will be great.
