# Imported from Fedora's shell_welcome; gradient rendering is self-contained.
function shell_welcome --description 'Show compact Fastfetch and Cowsay in three columns'
    set -l fortune_mood (shuf -n 1 -e b d g p s t w y)
    set -l cow_lines (fortune -a -s | fmt -25 -s | head -n 4 | cowsay -$fortune_mood -f small -n | shell_welcome_gradient | awk '
        {
            colored = $0
            plain = $0
            gsub(/\033\[[0-9;]*m/, "", plain)
            if (cow) print colored
            else {
                print plain
                if (plain ~ /^ -+$/) cow = 1
            }
        }
    ')
    set -l fetch_lines (fastfetch --pipe false --config $HOME/.config/fastfetch/shell.jsonc)
    set -l banner_lines (toilet -d @figlet@/share/figlet -f slant --filter crop moria | shell_welcome_gradient | sed 's/^/                    /')
    set -l left_lines $banner_lines '' $fetch_lines

    set -l left_width 0
    for line in $left_lines
        set -l plain (string replace -ra '\e\[[0-?]*[ -/]*[@-~]' '' -- $line)
        set -l width (string length -- $plain)
        if test $width -gt $left_width
            set left_width $width
        end
    end
    set -l cow_width 0
    for line in $cow_lines
        set -l plain (string replace -ra '\e\[[0-?]*[ -/]*[@-~]' '' -- $line)
        set -l width (string length -- $plain)
        if test $width -gt $cow_width
            set cow_width $width
        end
    end
    set -l columns 80
    if set -q COLUMNS; and test "$COLUMNS" -gt 0
        set columns $COLUMNS
    end
    set -l column_gap (math $columns - $left_width - $cow_width - 2)
    if test $column_gap -lt 3
        set column_gap 3
    end
    set -l left_count (count $left_lines)
    set -l cow_count (count $cow_lines)
    set -l cow_offset 0
    if test $left_count -gt $cow_count
        set cow_offset (math "floor(($left_count - $cow_count) / 2)")
    end
    set -l line_count $left_count
    set -l cow_end (math $cow_offset + $cow_count)
    if test $cow_end -gt $line_count
        set line_count $cow_end
    end
    for index in (seq $line_count)
        set -l left_line ''
        set -l cow_line ''
        if test $index -le $left_count
            set left_line $left_lines[$index]
        end
        set -l cow_index (math $index - $cow_offset)
        if test $cow_index -ge 1; and test $cow_index -le $cow_count
            set cow_line $cow_lines[$cow_index]
        end
        if test -n "$cow_line"
            set -l plain (string replace -ra '\e\[[0-?]*[ -/]*[@-~]' '' -- $left_line)
            set -l padding (math $left_width - (string length -- $plain) + $column_gap)
            printf '%s%*s%s\n' "$left_line" $padding '' "$cow_line"
        else
            printf '%s\n' "$left_line"
        end
    end
end

# Fedora's C lolcat gradient flags are not supported by Nixpkgs' Ruby lolcat.
function shell_welcome_gradient
    awk '{
        for (i = 1; i <= length($0); i++) {
            t = (length($0) > 1) ? (i - 1) / (length($0) - 1) : 0
            printf "\033[38;2;%d;%d;%dm%s", 54 + 85*t, 241 - 149*t, 205 + 41*t, substr($0, i, 1)
        }
        printf "\033[0m\n"
    }'
end
