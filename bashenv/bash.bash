
if [[ "$BASH_VERSINFO" -lt "4" ]]; then
	echo "!! Your system Bash is out of date: $BASH_VERSION"
	echo "!! Please upgrade to Bash 4 or greater."
	if [[ "$(uname)" == "Darwin" ]]; then
		echo
		echo "On OS X, use Homebrew to install latest Bash:"
		echo '   $ brew install bash'
		echo
		echo "Then add it to /etc/shells and change your user's shell:"
		echo '   $ sudo sh -c "echo /usr/local/bin/bash >> /etc/shells"'
		echo '   $ chsh -s /usr/local/bin/bash'
		echo
		echo "A new terminal session is then necessary to take effect."
		echo
	fi
	exit 2
fi
