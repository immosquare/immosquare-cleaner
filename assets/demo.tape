# Demo GIF of the README. Regenerate from the repository root:
#   vhs assets/demo.tape
# Needs vhs, bat and git-delta (brew install vhs bat git-delta).
# The setup is hidden: it writes the sample file in a throwaway
# directory, keeps a copy for the diff, points `immosquare-cleaner`
# at this checkout and aliases `diff` to a side-by-side delta.

Output assets/demo.gif

Set Shell "bash"
Set FontSize 18
Set Width 1500
Set Height 640
Set Padding 28
Set Theme "Catppuccin Mocha"
Set TypingSpeed 30ms

Hide
Type "export PS1='$ ' REPO=$PWD BAT_THEME='Catppuccin Mocha' && cd $(mktemp -d) && git init -q"
Enter
Type `immosquare-cleaner() { BUNDLE_GEMFILE=$REPO/Gemfile bundle exec ruby -I$REPO/lib $REPO/bin/immosquare-cleaner "$@"; }`
Enter
Type `printf '%s\n' 'class User<ApplicationRecord' '    has_many :orders,dependent: :destroy' '  # name shown in the header' '  def display_name' "        name=[first_name,last_name].compact.join(' ')" "     return name.blank? ? 'Anonymous' : name" '  end' '    def total_spent()' '      orders.map{|o| o.amount}.sum' '    end' '  def admin?' "    return role == 'admin' ? true : false" '  end' 'end' > user.rb && cp user.rb before.rb`
Enter
Type `alias diff="delta --side-by-side --line-numbers --paging=never --hunk-header-style=omit --syntax-theme='Catppuccin Mocha'"`
Enter
Type "clear"
Enter
Show

Type "# Claude Code just wrote user.rb"
Enter
Sleep 500ms
Type "bat --style=numbers --paging=never user.rb"
Enter
Sleep 3s

Type "# its PostToolUse hook runs immosquare-cleaner --hook"
Enter
Sleep 500ms
Type `echo '{"tool_input":{"file_path":"user.rb"}}' | immosquare-cleaner --hook 2>&1 | tail -1`
Enter
Sleep 4s

Hide
Type "clear"
Enter
Show

Type "diff before.rb user.rb"
Enter
Sleep 8s
