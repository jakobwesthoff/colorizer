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
COLORIZER_yellow=${COLORIZER_yellow:="0;33"}
COLORIZER_gray=${COLORIZER_gray:="1;30"}
COLORIZER_light_blue=${COLORIZER_light_blue:="1;34"}
COLORIZER_light_green=${COLORIZER_light_green:="1;32"}
COLORIZER_light_cyan=${COLORIZER_light_cyan:="1;36"}
COLORIZER_light_red=${COLORIZER_light_red:="1;31"}
COLORIZER_light_purple=${COLORIZER_light_purple:="1;35"}
COLORIZER_light_yellow=${COLORIZER_light_yellow:="1;33"}
COLORIZER_light_gray=${COLORIZER_light_gray:="0;37"}

# Somewhat special colors

##
# Add escape sequences to defined color codes
#
# Must never be called outside of this script, as it only is allowed to be
# called once
#
# It's only a function to allow local variables
##
COLORIZER_add_escape_sequences() {
    local color
    for color in blue green cyan red purple yellow gray; do
        eval "COLORIZER_${color}=\"\${COLORIZER_START}\${COLORIZER_${color}}\${COLORIZER_END}\""
        eval "COLORIZER_light_${color}=\"\${COLORIZER_START}\${COLORIZER_light_${color}}\${COLORIZER_END}\""
    done

    for color in black white none; do
        eval "COLORIZER_${color}=\"\${COLORIZER_START}\${COLORIZER_${color}}\${COLORIZER_END}\""
    done
}
COLORIZER_black=${COLORIZER_black:="0;30"}
COLORIZER_white=${COLORIZER_white:="1;37"}
COLORIZER_none=${COLORIZER_none:="0"}

##
# Parse the input and return the ansi code output processed output
##
COLORIZER_process_input() {
    local processed="${*}"
    local pseudoTag=""

    local stack
    ARRAY_define "stack"

    local result=""

    result="${processed%%<*}"
    if [ "${result}" != "" ] && [ "${result}" != "${processed}" ]; then
        # Cut outer content, which has been processed already
        processed="<${processed#*<}"
    fi
    while [ "${processed#*<}" != "${processed}" ]; do
        # Isolate first tag in stream
        pseudoTag="${processed#*<}"
        pseudoTag="${pseudoTag%%>*}"

        # Push/Pop tag to/from stack
        if [ "${pseudoTag:0:1}" != "/" ]; then
            ARRAY_push "stack" "${pseudoTag}"
        else
            if [ "${pseudoTag:1}" != "$(ARRAY_peek "stack")" ]; then
                echo "Mismatching colorize tag nesting at <$(ARRAY_peek "stack")>...<${pseudoTag}>"
                exit 42
            fi
            ARRAY_pop "stack" >/dev/null
        fi

        # Apply ansi formatting
        pseudoTag="${pseudoTag/-/_}"
        if [ "${pseudoTag:0:1}" != "/" ]; then
            # Opening Tag
            eval "result=\"\${result}\${COLORIZER_${pseudoTag}}\""
        else
            # Closing Tag
            if [ "$(ARRAY_count "stack")" -eq 0 ]; then
                result="${result}${COLORIZER_none}"
            else
                eval "result=\"\${result}\${COLORIZER_$(ARRAY_peek "stack")}\""
            fi
        fi

        # Cut processed portion from stream
        processed="${processed#*>}"
        
        # Update result with next content part
        result="${result}${processed%%<*}"
    done

    if [ "$(ARRAY_count "stack")" -ne 0 ]; then
        echo "Could not find closing tag for <$(ARRAY_peek "stack")>"
        exit 42
    fi

    result="${result//&lt;/<}"
    result="${result//&gt;/>}"
    echo "${result}"
}

##
# Parse a given colorize string and output the correctly escaped ansi-code
# formatted string for it.
#
# This function is the only public API method to this utillity
#
# echo -e is used for output.
#
# The -n option may be specified, which will behave exactly like echo -n, aka
# omitting the newline.
#
# @option -n omit the newline
# @param [string,...]
##
colorize() {
    local OPTIND=1
    local newline_option=""
    local option=""
    while getopts ":n" option; do
        case "${option}" in
            n) newline_option="SET";;
            \?) echo "Invalid option (-${OPTARG}) given to colorize"; exit 42;;
        esac
    done
    shift $((OPTIND-1))

    local processed_message="$(COLORIZER_process_input "${@}")"

    if [ "${newline_option}" = "SET" ]; then
        echo -en "${processed_message}"
    else
        echo -e "${processed_message}"
    fi
}

# Allow alternate spelling
alias colourise=colorize

# Initialize the color codes
COLORIZER_add_escape_sequences
