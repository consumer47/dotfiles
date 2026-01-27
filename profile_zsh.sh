#!/bin/bash

echo "=== ZSH Startup Time Profiler ==="
echo ""

# Test overall startup time
echo "1. Overall ZSH startup time (5 runs):"
for i in {1..5}; do
    time zsh -i -c exit 2>&1 | grep real
done
echo ""

# Test with minimal config
echo "2. Testing with minimal .zshrc (backup current config first):"
echo "   Run: mv ~/.zshrc ~/.zshrc.backup && echo 'echo minimal' > ~/.zshrc"
echo "   Then: time zsh -i -c exit"
echo "   Restore: mv ~/.zshrc.backup ~/.zshrc"
echo ""

# Profile specific components
echo "3. Component timing (approximate):"
echo "   To get detailed profiling, add this to the top of your .zshrc:"
echo "   zmodload zsh/zprof"
echo "   And this to the bottom:"
echo "   zprof"
echo ""

echo "4. Check if these files exist and are readable:"
files_to_check=(
    "~/.p10k.zsh"
    "~/powerlevel10k/powerlevel10k.zsh-theme"
    "~/.oh-my-zsh/oh-my-zsh.sh"
    "~/.commonrc"
    "~/.privaterc"
    "~/.nvm/nvm.sh"
    "~/.nvm/bash_completion"
)

for file in "${files_to_check[@]}"; do
    if [ -f "${file/#\~/$HOME}" ]; then
        echo "   ✓ $file exists"
    else
        echo "   ✗ $file missing"
    fi
done 