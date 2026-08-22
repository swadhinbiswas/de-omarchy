# 50-de-omarchy.zsh — installed by de-omarchy (additive; your .zshrc already
# sources ~/.config/zshrc.d/*.zsh, so nothing else was modified).

if [[ -d /usr/share/de-omarchy ]]; then
  export OMARCHY_PATH=/usr/share/de-omarchy
elif [[ -d "$HOME/.local/share/de-omarchy" ]]; then
  export OMARCHY_PATH="$HOME/.local/share/de-omarchy"
fi

if [[ -n $OMARCHY_PATH && -d $OMARCHY_PATH/bin ]]; then
  case ":$PATH:" in
    *":$OMARCHY_PATH/bin:"*) ;;
    *) PATH="$OMARCHY_PATH/bin:$PATH" ;;
  esac

  # Convenience alias matching upstream muscle memory.
  alias o='omarchy'
fi
