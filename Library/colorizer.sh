####
# Copyright (c) 2012, Jakob Westhoff <jakob@qafoo.com>
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#  - Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#  - Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
####

source "${COLORIZE_SH_SOURCE_DIR:-$( cd "$( dirname "${BASH_SOURCE:-${0}}" )" && pwd )}/Compatibility/compatibility.sh"

# Escape codes
COLORIZER_START=${COLORIZER_START:="\033["}
COLORIZER_END=${COLORIZER_END:="m"}

# Default colors
COLORIZER_blue=${COLORIZER_blue:="0;34"}
COLORIZER_green=${COLORIZER_green:="0;32"}
COLORIZER_cyan=${COLORIZER_cyan:="0;36"}
COLORIZER_red=${COLORIZER_red:="0;31"}
COLORIZER_purple=${COLORIZER_purple:="0;35"}
COLORIZER_magenta=${COLORIZER_magenta:="${COLORIZER_purple}"}
COLORIZER_yellow=${COLORIZER_yellow:="0;33"}
COLORIZER_gray=${COLORIZER_gray:="1;30"}
COLORIZER_light_blue=${COLORIZER_light_blue:="1;34"}
COLORIZER_light_green=${COLORIZER_light_green:="1;32"}
COLORIZER_light_cyan=${COLORIZER_light_cyan:="1;36"}
COLORIZER_light_red=${COLORIZER_light_red:="1;31"}
COLORIZER_light_purple=${COLORIZER_light_purple:="1;35"}
COLORIZER_light_magenta=${COLORIZER_light_magenta:="${COLORIZER_light_purple}"}
COLORIZER_light_yellow=${COLORIZER_light_yellow:="1;33"}
COLORIZER_light_gray=${COLORIZER_light_gray:="0;37"}

# Somewhat special colors
COLORIZER_black=${COLORIZER_black:="0;30"}
COLORIZER_white=${COLORIZER_white:="1;37"}
COLORIZER_none=${COLORIZER_none:="0"}

# Background colors (text on colored background)
COLORIZER_bg_blue=${COLORIZER_bg_blue:="0;37;44"}
COLORIZER_bg_green=${COLORIZER_bg_green:="0;30;42"}
COLORIZER_bg_cyan=${COLORIZER_bg_cyan:="0;30;46"}
COLORIZER_bg_red=${COLORIZER_bg_red:="0;37;41"}
COLORIZER_bg_purple=${COLORIZER_bg_purple:="0;37;45"}
COLORIZER_bg_magenta=${COLORIZER_bg_magenta:="${COLORIZER_bg_purple}"}
COLORIZER_bg_yellow=${COLORIZER_bg_yellow:="0;30;43"}
COLORIZER_bg_gray=${COLORIZER_bg_gray:="0;37;47"}
COLORIZER_bg_light_blue=${COLORIZER_bg_light_blue:="0;30;104"}
COLORIZER_bg_light_green=${COLORIZER_bg_light_green:="0;30;102"}
COLORIZER_bg_light_cyan=${COLORIZER_bg_light_cyan:="0;30;106"}
COLORIZER_bg_light_red=${COLORIZER_bg_light_red:="0;30;101"}
COLORIZER_bg_light_purple=${COLORIZER_bg_light_purple:="0;30;105"}
COLORIZER_bg_light_magenta=${COLORIZER_bg_light_magenta:="${COLORIZER_bg_light_purple}"}
COLORIZER_bg_light_yellow=${COLORIZER_bg_light_yellow:="0;30;103"}
COLORIZER_bg_light_gray=${COLORIZER_bg_light_gray:="0;30;47"}
COLORIZER_bg_black=${COLORIZER_bg_black:="0;37;40"}
COLORIZER_bg_white=${COLORIZER_bg_white:="0;30;107"}

# Bright colors, from the terminal's bright palette. The light_* colors above
# are bold plus the normal color, which looks like the normal color in
# terminals that do not render bold.
COLORIZER_bright_black=${COLORIZER_bright_black:="90"}
COLORIZER_bright_red=${COLORIZER_bright_red:="91"}
COLORIZER_bright_green=${COLORIZER_bright_green:="92"}
COLORIZER_bright_yellow=${COLORIZER_bright_yellow:="93"}
COLORIZER_bright_blue=${COLORIZER_bright_blue:="94"}
COLORIZER_bright_purple=${COLORIZER_bright_purple:="95"}
COLORIZER_bright_magenta=${COLORIZER_bright_magenta:="${COLORIZER_bright_purple}"}
COLORIZER_bright_cyan=${COLORIZER_bright_cyan:="96"}
COLORIZER_bright_white=${COLORIZER_bright_white:="97"}

# Text attributes. Without a leading reset, so an attribute inside a color
# keeps the color. `4:2` is a double underline; terminals without it show a
# single one.
COLORIZER_bold=${COLORIZER_bold:="1"}
COLORIZER_dim=${COLORIZER_dim:="2"}
COLORIZER_italic=${COLORIZER_italic:="3"}
COLORIZER_underline=${COLORIZER_underline:="4"}
COLORIZER_double_underline=${COLORIZER_double_underline:="4:2"}
COLORIZER_reverse=${COLORIZER_reverse:="7"}
COLORIZER_strike=${COLORIZER_strike:="9"}

##
# Parse the input and return the ansi code output processed output
#
# Malformed markup is reported on stderr, and the function exits with 42
# (it runs in a subshell). In lenient mode the nesting is not checked at all,
# which together with the strip option gives the bare text of input that
# failed the check.
#
# @param prompt_option SET to escape ansi for prompt usage
# @param strip_option SET to remove the tags instead of replacing them
# @param lenient_option SET to skip the nesting check; only with strip_option
# @param [string,...]
##
COLORIZER_process_input() {
    local prompt_option="${1}"
    local strip_option="${2}"
    local lenient_option="${3}"
    shift 3
    local processed="${*}"
    local pseudoTag=""
    local parentTag=""

    local stack
    ARRAY_define "stack"

    local result=""
    local ansiToken=""

    result="${processed%%<*}"
    if [ "${result}" != "" ] && [ "${result}" != "${processed}" ]; then
        # Cut outer content, which has been processed already
        processed="<${processed#*<}"
    fi
    while [ "${processed#*<}" != "${processed}" ]; do
        # Isolate first tag in stream
        pseudoTag="${processed#*<}"

        # A `<` with no `>` after it cannot start a tag, so the rest of the
        # text, from that `<` on, is plain text. Cutting up to the next `>`
        # would find none and never move on.
        if [ "${pseudoTag#*>}" = "${pseudoTag}" ]; then
            result="${result}<${pseudoTag}"
            break
        fi

        pseudoTag="${pseudoTag%%>*}"

        # Only names that can be part of a variable name are tags. Anything
        # else between `<` and `>`, including nothing, is plain text, so it
        # never reaches the palette lookup's `eval` as code.
        case "${pseudoTag#/}" in
            "" | *[!A-Za-z0-9_-]*)
                result="${result}<${pseudoTag}>"
                processed="${processed#*>}"
                result="${result}${processed%%<*}"
                continue
                ;;
        esac

        # Push/Pop tag to/from stack, unless the nesting is not checked
        if [ -z "${lenient_option}" ]; then
            if [ "${pseudoTag:0:1}" != "/" ]; then
                ARRAY_push "stack" "${pseudoTag}"
            else
                if [ "${pseudoTag:1}" != "$(ARRAY_peek "stack")" ]; then
                    echo "Mismatching colorize tag nesting at <$(ARRAY_peek "stack")>...<${pseudoTag}>" >&2
                    exit 42
                fi
                ARRAY_pop "stack" >/dev/null
            fi
        fi

        # Apply ansi formatting
        if [ -z "${strip_option}" ]; then
            pseudoTag="${pseudoTag//-/_}"
            if [ "${pseudoTag:0:1}" != "/" ]; then
                # Opening Tag
                eval "ansiToken=\"\${COLORIZER_${pseudoTag}}\""
            else
                # Closing Tag
                if [ "$(ARRAY_count "stack")" -eq 0 ]; then
                    ansiToken="${COLORIZER_none}"
                else
                    # The stack holds tag names as written, so the parent's
                    # name needs the same mapping as an opening tag's.
                    parentTag="$(ARRAY_peek "stack")"
                    eval "ansiToken=\"\${COLORIZER_${parentTag//-/_}}\""
                fi
            fi

            # Add escape codes
            ansiToken="${COLORIZER_START}${ansiToken}${COLORIZER_END}"
            if [ "${prompt_option}" = "SET" ]; then
                ansiToken="\[${ansiToken}\]"
            fi

            result="${result}${ansiToken}"
        fi

        # Cut processed portion from stream
        processed="${processed#*>}"

        # Update result with next content part
        result="${result}${processed%%<*}"
    done

    if [ "$(ARRAY_count "stack")" -ne 0 ]; then
        echo "Could not find closing tag for <$(ARRAY_peek "stack")>" >&2
        exit 42
    fi

    result="${result//&lt;/<}"
    result="${result//&gt;/>}"

    # Backslash sequences are interpreted once, by colorize's output. zsh's
    # `echo` would interpret them here already.
    printf '%s\n' "${result}"
}

##
# Parse a given colorize string and output the correctly escaped ansi-code
# formatted string for it.
#
# This function is the only public API method to this utillity
#
# printf '%b' is used for output, which interprets backslash sequences like
# echo -e.
#
# For malformed markup, the error message goes to stderr, the text is printed
# without its tags, and the status is 42. An invalid option is reported on
# stderr with status 42 as well.
#
# The -n option may be specified, which will behave exactly like echo -n, aka
# omitting the newline.
#
# To use ansi in a prompt without behaving badly, using the -p option.
#
# @option -n omit the newline
# @option -p escape ansi for prompt usage
# @option -s instead of replacing with ansi, just strip the tags
# @param [string,...]
##
colorize() {
    local OPTIND=1
    local newline_option=""
    local prompt_option=""
    local strip_option=""
    local option=""
    while getopts ":nps" option; do
        case "${option}" in
            n) newline_option="SET";;
            p) prompt_option="SET";;
            s) strip_option="SET";;
            # On stderr, so the message never ends up in captured output;
            # returned, so the calling script goes on.
            \?) echo "Invalid option (-${OPTARG}) given to colorize" >&2; return 42;;
        esac
    done
    shift $((OPTIND-1))

    # Declared apart from the assignment, as `local` would replace the
    # parser's status with its own.
    local processed_message
    processed_message="$(COLORIZER_process_input "${prompt_option}" "${strip_option}" "" "${@}")"
    local process_status="${?}"

    # The parser has reported malformed markup on stderr. The text is still
    # printed, without any tags, so captured output stays readable.
    if [ "${process_status}" -ne 0 ]; then
        processed_message="$(COLORIZER_process_input "" "SET" "SET" "${@}")"
    fi

    # `%b` interprets backslash sequences as `echo -e` does, but never takes
    # the text for an option of its own, as `echo` does with `-n` or `-e`.
    # Unlike `echo -e`, bash's printf warns about sequences it cannot
    # complete, such as `\u` in a bash prompt string; it prints them as they
    # are either way, so the warning is dropped.
    if [ "${newline_option}" = "SET" ]; then
        printf '%b' "${processed_message}" 2> /dev/null
    else
        printf '%b\n' "${processed_message}" 2> /dev/null
    fi

    # Returned rather than exited with, so a calling script or an
    # interactive shell that loaded the library goes on.
    return "${process_status}"
}

# Allow alternate spelling. A function rather than an alias, as bash does not
# expand aliases in scripts.
colourise() {
    colorize "$@"
}
