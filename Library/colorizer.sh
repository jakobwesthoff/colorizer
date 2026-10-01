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

# Whether to color: `always` (the default), `never`, or `auto`, which colors
# when the output is a terminal, NO_COLOR is unset or empty and TERM is not
# `dumb`. `auto` is decided by colorize_detect, once when the library is
# loaded and whenever the caller runs it again; COLORIZER_ENABLED holds that
# decision.
COLORIZER_MODE=${COLORIZER_MODE:="always"}

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

    # Without colors the tags are removed, as with -s.
    if ! COLORIZER_colors_enabled; then
        strip_option="SET"
    fi

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

##
# Print the escape sequence of one or more tags, combined into one
#
# For programs that render text themselves (a jq program, a printf format)
# and only need the codes. Tag names are looked up as in colorize, so custom
# tags work. Every palette code but the first loses a leading `0;`, so a
# later tag adds to the earlier ones instead of resetting them:
# `colorize_code bold red` gives ESC[1;31m.
#
# @option -v name assign the sequence to the variable instead of printing it;
#                 names starting with `colorizer_` are reserved, as the
#                 function's own variables would hide them
# @param tag...
# @return 1 for an undefined or invalid tag name, no tag, or an invalid
#         variable name; 42 for an invalid option
##
colorize_code() {
    # Shell variables are scoped dynamically: a name refers to the innermost
    # variable of that name along the call chain. With `-v code`, the
    # assignment at the end resolves `code` here first, so a local of that
    # name would receive the sequence and take it along on return, leaving
    # the caller's variable untouched. Every local of this function therefore
    # carries the `colorizer_` prefix, which callers must not use for `-v`.
    # Namerefs (`local -n`) would avoid this, but need bash 4.3 and do not
    # exist in zsh or busybox ash.
    local OPTIND=1
    local colorizer_option=""
    local colorizer_target=""
    while getopts ":v:" colorizer_option; do
        case "${colorizer_option}" in
            v) colorizer_target="${OPTARG}";;
            :) echo "Option -${OPTARG} of colorize_code needs a variable name" >&2; return 42;;
            \?) echo "Invalid option (-${OPTARG}) given to colorize_code" >&2; return 42;;
        esac
    done
    shift $((OPTIND-1))

    if [ "${#}" -eq 0 ]; then
        echo "colorize_code needs at least one tag" >&2
        return 1
    fi

    # The variable name ends up in evaluated code, so it has to be one.
    case "${colorizer_target}" in
        [!A-Za-z_]* | *[!A-Za-z0-9_]*)
            echo "Invalid variable name for colorize_code -v: ${colorizer_target}" >&2
            return 1
            ;;
    esac

    local colorizer_codes=""
    local colorizer_tag=""
    local colorizer_code=""
    for colorizer_tag in "${@}"; do
        # Validated before the lookup's `eval`, as in colorize.
        case "${colorizer_tag}" in
            "" | *[!A-Za-z0-9_-]*)
                echo "Invalid colorize tag name <${colorizer_tag}>" >&2
                return 1
                ;;
        esac

        if eval "[ -z \"\${COLORIZER_${colorizer_tag//-/_}+set}\" ]"; then
            echo "Unknown colorize tag <${colorizer_tag}>" >&2
            return 1
        fi
        eval "colorizer_code=\"\${COLORIZER_${colorizer_tag//-/_}}\""

        if [ -z "${colorizer_codes}" ]; then
            colorizer_codes="${colorizer_code}"
        elif [ -n "${colorizer_code}" ]; then
            colorizer_codes="${colorizer_codes};${colorizer_code#0;}"
        fi
    done

    # Without colors the sequence is empty, so callers can use it either way.
    if ! COLORIZER_colors_enabled; then
        if [ -n "${colorizer_target}" ]; then
            eval "${colorizer_target}=''"
        fi
        return 0
    fi

    if [ -z "${colorizer_target}" ]; then
        printf '%b' "${COLORIZER_START}${colorizer_codes}${COLORIZER_END}"
    elif [ -n "${BASH_VERSION:-}${ZSH_VERSION:-}" ]; then
        printf -v "${colorizer_target}" '%b' "${COLORIZER_START}${colorizer_codes}${COLORIZER_END}"
    else
        # Other shells have no `printf -v`, and pay for a subshell.
        eval "${colorizer_target}=\"\$(printf '%b' \"\${COLORIZER_START}\${colorizer_codes}\${COLORIZER_END}\")\""
    fi
}

##
# Decide whether colorize and colorize_code color their output
#
# Only `auto` needs a decision; `always` and `never` apply as they are, also
# when COLORIZER_MODE changes later. The library runs this once when it is
# loaded. Run it again in your own shell, not inside `$(...)`, after changing
# COLORIZER_MODE to `auto` or redirecting the output: inside `$(...)` stdout
# is a pipe, never a terminal.
#
# @param fd the file descriptor to check, 1 (stdout) by default; 2 for a
#           program that prints its colored output to stderr
# @return 1 for an invalid file descriptor or an unknown COLORIZER_MODE,
#         which colors as `always` does
##
colorize_detect() {
    local fd="${1:-1}"

    case "${fd}" in
        "" | *[!0-9]*)
            echo "Invalid file descriptor for colorize_detect: ${fd}" >&2
            return 1
            ;;
    esac

    case "${COLORIZER_MODE}" in
        always) COLORIZER_ENABLED="yes";;
        never) COLORIZER_ENABLED="no";;
        auto)
            if [ -t "${fd}" ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
                COLORIZER_ENABLED="yes"
            else
                COLORIZER_ENABLED="no"
            fi
            ;;
        *)
            COLORIZER_ENABLED="yes"
            echo "Unknown COLORIZER_MODE: ${COLORIZER_MODE}" >&2
            return 1
            ;;
    esac
}

##
# Whether to color now: `never` and `always` apply directly, `auto` uses the
# last decision of colorize_detect, and an unknown mode colors
##
COLORIZER_colors_enabled() {
    case "${COLORIZER_MODE}" in
        never) return 1;;
        auto) [ "${COLORIZER_ENABLED:-yes}" = "yes" ];;
        *) return 0;;
    esac
}

# Allow alternate spelling. A function rather than an alias, as bash does not
# expand aliases in scripts.
colourise() {
    colorize "$@"
}

# Decide `auto` now, in the shell that loads the library. An unknown mode is
# reported, but does not fail the loading.
colorize_detect || :
