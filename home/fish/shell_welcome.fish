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
    # Top-position output has real lines; the default left logo uses cursor
    # movements, which cannot be measured or padded as independent strings.
    set -l fetch_output (fastfetch --pipe false --logo-position top --config $HOME/.config/fastfetch/shell.jsonc)
    set -l logo_lines
    set -l info_lines
    set -l in_info 0
    for line in $fetch_output
        if test $in_info -eq 1
            set -a info_lines "$line"
        else if test (string length --visible -- "$line") -eq 0
            set in_info 1
        else
            set -a logo_lines "$line"
        end
    end
    set -l logo_width 0
    for line in $logo_lines
        set logo_width (math "max($logo_width, "(string length --visible -- "$line")")")
    end
    set -l fetch_lines
    for index in (seq (math "max("(count $logo_lines)", "(count $info_lines)")"))
        set -l logo_line ''
        set -l info_line ''
        if test $index -le (count $logo_lines)
            set logo_line $logo_lines[$index]
        end
        if test $index -le (count $info_lines)
            set info_line $info_lines[$index]
        end
        set -l padding (math $logo_width - (string length --visible -- "$logo_line") + 2)
        set -a fetch_lines (printf '%s\e[0m%*s%s' "$logo_line" $padding '' "$info_line")
    end
    set -l banner_lines (toilet -d @figlet@/share/figlet -f slant --filter crop moria | shell_welcome_gradient | sed 's/^/                    /')
    set -l left_lines $banner_lines '' $fetch_lines

    set -l left_width 0
    for line in $left_lines
        set -l width (string length --visible -- "$line")
        if test $width -gt $left_width
            set left_width $width
        end
    end
    set -l cow_width 0
    for line in $cow_lines
        set -l width (string length --visible -- "$line")
        if test $width -gt $cow_width
            set cow_width $width
        end
    end
    set -l columns 80
    if set -q COLUMNS; and test "$COLUMNS" -gt 0
        set columns $COLUMNS
    end
    set -l column_gap 3
    # Stack only when the actual visible columns cannot fit side by side.
    if test (math $left_width + $column_gap + $cow_width) -ge $columns
        printf '%s\n' $left_lines '' $cow_lines
        return
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
            set -l padding (math $left_width - (string length --visible -- "$left_line") + $column_gap)
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
