set -U fish_greeting ""

if status is-interactive
    fish_config theme choose terminal
end

function conda
    # 1. Wipe this function so it doesn't loop
    functions --erase conda

    # 2. Source the actual conda setup script
    if test -f /home/elementrix/miniconda3/etc/fish/conf.d/conda.fish
        source /home/elementrix/miniconda3/etc/fish/conf.d/conda.fish
    else
        # Fallback to the binary hook if the script is missing
        eval /home/elementrix/miniconda3/bin/conda "shell.fish" "hook" | source
    end

    # 3. Run the actual conda command with the arguments you provided
    conda $argv
end

function dirsource
    set -f envdir "$argv"

    if not test -d "$envdir"
        echo "Directory not found: $envdir"
        return 1
    end

    for envfile in "$envdir"/*
        # Skip if it's a directory or not a regular file
        if not test -f "$envfile"
            continue
        end

        # Source each file
        while read -l line
            # Ignore comments and empty lines
            if not string match -qr '^#|^$' "$line"
                set -l item (string split -m 1 '=' $line)
                
                # Ensure we have a valid key-value pair
                if test (count $item) -eq 2
                    set -gx $item[1] $item[2]
                    
                    # Special check for PATH manipulation
                    # We check if the key is literally 'PATH'
                    if test "$item[1]" = "PATH"
                        set -gx PATH $item[2] $PATH
                    end
                end
            end
        end < "$envfile"
    end
end

dirsource ~/.config/environment.d
