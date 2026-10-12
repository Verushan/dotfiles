function fish_prompt
    set -l last_status $status
    set -l blue (set_color blue)
    set -l green (set_color green)
    set -l red (set_color red)
    set -l normal (set_color normal)
    set -l current_dir (basename (prompt_pwd))

    # Change arrow color to red if previous command failed
    set -l prompt_color $blue
    if test $last_status -ne 0
        set prompt_color $red
    end

    # Layout: [Directory] Arrow
    echo -n -s $green [$current_dir] " " $prompt_color "->" $normal " "
end
