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
#
# This file does include a generic compatibility layer for accessing arrays in
# bash.
#
####

##
# Define a variable as an empty array
#
# The variable should already exist in the scope you want to use it in
#
# @param name
##
ARRAY_define() {
    local name="${1}"

    eval "${name}=()"
}

##
# Get the current amount of entries inside an existing array
#
# @param name
##
ARRAY_count() {
    local name="${1}"

    # `set +u` lets an array that was never defined count as empty under a
    # caller's `set -u`; empty values still count as elements.
    (set +u; eval "echo \"\${#${name}[@]}\"")
}

##
# Get a certain index stored inside an array
#
# The index is zero based. The first entry entry is therefore supposed to be 0.
# If the used shell does only provide 1-based arrays this needs to be mapped
# inside of this function accordingly
#
# @param name
# @param index
##
ARRAY_get() {
    local name="${1}"
    local index="${2}"

    eval "echo \"\${${name}[${index}]}\""
}

##
# Set a certain value stored to a certain index inside an array
#
# The index is zero based. The first entry entry is therefore supposed to be 0.
# If the used shell does only provide 1-based arrays this needs to be mapped
# inside of this function accordingly
#
# @param name
# @param index
# @param value
##
ARRAY_set() {
    local name="${1}"
    local index="${2}"
    local value="${3}"

    # The evaluated code names the value instead of containing it, so the
    # value is expanded once, as data, and never parsed as shell code.
    eval "${name}[${index}]=\"\${value}\""
}

##
# Push a given value to the end of the provided array name
#
# @param name
# @param value
##
ARRAY_push() {
    local name="${1}"
    local value="${2}"

    # The evaluated code names the value instead of containing it, so the
    # value is expanded once, as data, and never parsed as shell code.
    eval "${name}[\${#${name}[@]}]=\"\${value}\""
}

##
# Peek at a value from the end of the provided array name without removing it
#
# @param name
##
ARRAY_peek() {
    local name="${1}"

    # An empty array has no last index; -1 would be a bad subscript.
    if eval "[ \"\${#${name}[@]}\" -eq 0 ]"; then
        echo ""
        return 0
    fi

    eval "echo \"\${${name}[\${#${name}[@]}-1]}\""
}

##
# Pop a value from the end of the provided array name
#
# @param name
##
ARRAY_pop() {
    local name="${1}"

    echo "$(ARRAY_peek "${name}")"

    # Nothing to remove from an empty array, and no last index to name.
    if eval "[ \"\${#${name}[@]}\" -eq 0 ]"; then
        return 0
    fi

    eval "unset \"${name}[\${#${name}[@]}-1]\""
}

##
# Unset a certain index from the given array
#
# @param name
##
ARRAY_unset() {
    local name="${1}"
    local index="${2}"

    eval "unset ${name}[${index}]"

    # `unset` leaves a hole, while peek and push expect the indexes 0 to
    # count - 1. Re-packing moves the later elements down, as in zsh. The
    # `+` form keeps an emptied array from failing `set -u` before bash 4.4.
    eval "${name}=(\${${name}[@]+\"\${${name}[@]}\"})"
}
