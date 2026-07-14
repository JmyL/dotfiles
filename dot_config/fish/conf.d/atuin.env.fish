
if test -f "$HOME/.atuin/bin/env.fish"
    source "$HOME/.atuin/bin/env.fish"
end

if command -q atuin
    atuin init fish | source
end
