usage() {
    >&2 echo "$(basename "$0") <data-dir>"
}

error_and_exit() {
    >&2 echo "$1"
    exit ${2:-1}
}

strip-newline () {
    tr -d '\n'
}

# usage: extract-substr <file> <(extended) regex>
# The Regex must contain exactly one caputre group, which will be output.
# Nothing else from the file is output.
extract-substr() {
    FILE="$1"
    REGEX="$2"
    cat "$FILE" | sed --silent --regexp-extended "s/$REGEX/\1/p" | tr --delete '\n'
}
 
