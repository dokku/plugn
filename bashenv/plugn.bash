
version() {
	declare desc="Show version"
	echo "plugn: ${PLUGN_VERSION:-dev}"
}

install() {
	declare desc="Install a new plugin from a Git URL"
	declare url="$1" name="$2"
	local basefilename
	basefilename="$(basename "$url")"
	if [[ "$url" == s3://* ]]; then
		install-s3 "$url" "$name"
	elif [[ "$basefilename" == *.tar.gz ]] || [[ "$basefilename" == *.tgz ]]; then
		install-tar "$url" "$name"
	else
		install-git "$url" "$name"
	fi
}

install-git() {
	declare desc="Install a plugin from git URL"
	declare url="$1" name="$2"
	pushd "$PLUGIN_PATH/available" &>/dev/null
	git clone "$url" $name
	popd &> /dev/null
}

install-s3() {
	declare desc="Install a plugin from git URL"
	declare url="$1" name="$2"
	local downloader args contents_dirs contents_files cwd

	which s3cmd > /dev/null && downloader="s3cmd" && args="get -q --force"
	which aws > /dev/null && downloader="aws" && args="s3 cp --quiet"

	if [[ -z "$downloader" ]]; then
		echo "Please install either awscli or s3cmd to install via s3" 1>&2
		exit 1
	fi
	download-and-extract-tar "$url" "$name" "$downloader" "$args"
}

install-tar() {
	declare desc="Install a plugin from tar URL"
	declare url="$1" name="$2"
	local downloader args

	which curl > /dev/null 2>&1 && downloader="curl" && args="-sL"
	which wget > /dev/null 2>&1 && downloader="wget" && args="-q --max-redirect=1 -O-"

	if [[ -z "$downloader" ]]; then
		echo "Please install either curl or wget to install via tar.gz" 1>&2
		exit 1
	fi
	download-and-extract-tar "$url" "$name" "$downloader" "$args"
}

download-and-extract-tar() {
	declare desc="Downloads and extracts a tar file"
	declare url="$1" name="$2" downloader="$3" args="$4"
	local contents_dirs contents_files cwd

	pushd "$PLUGIN_PATH/available" &>/dev/null
	mkdir -p "$name" && \
		"$downloader" $args "$url" | tar xz -C "$name" && \
		pushd "$name" &>/dev/null

	# make sure we untarred a single dir into our target
	contents_dirs=($(find . -maxdepth 1 -not -path '.' -type d))
	contents_files=($(find . -maxdepth 1 -type f))
	if [[ "${#contents_dirs[@]}" -eq 1 ]] && [[ "${#content_files[@]}" -eq 0 ]]; then
		pushd ./* &>/dev/null && \
			find . -maxdepth 1 -not -path '.' -exec mv -f {} ../ \;
		cwd="$PWD"
		popd &>/dev/null
		rmdir "$cwd"
	fi
	popd &> /dev/null
}

uninstall() {
	declare desc="Remove plugin from available plugins"
	declare plugin="$1"
	rm -rf "$PLUGIN_PATH/enabled/$plugin"
	rm -rf "$PLUGIN_PATH/available/$plugin"
}

update() {
	declare desc="Update plugin and optionally pin to commit/tag/branch"
	declare plugin="$1" committish="$2"
	[[ ! -d "$PLUGIN_PATH/available/$plugin" ]] && echo "Plugin ($plugin) not installed" && exit 1
	pushd "$PLUGIN_PATH/available/$plugin" &>/dev/null
	[[ -z "$committish" ]] && [[ ! $(git symbolic-ref HEAD) ]] && echo "Plugin pinned to $(< ./.plugin_committish)" && exit 0
	git checkout master &> /dev/null
	git pull &> /dev/null
	git checkout - &> /dev/null
	if [[ -n "$committish" ]]; then
		git fetch --tags &> /dev/null
		git checkout $committish &> /dev/null
		echo "$committish" > ./.plugin_committish
		echo "Plugin ($plugin) updated and pinned to $committish"
	else
		echo "Plugin ($plugin) updated"
	fi
	popd &> /dev/null
}

list() {
	declare desc="List all local plugins"
	shopt -s nullglob
	for path in $PLUGIN_PATH/available/*; do
		local plugin="$(basename $path)"
		local status="$([[ -e $PLUGIN_PATH/enabled/$plugin ]] && echo enabled || echo disabled)"
		local version="$(cat $path/plugin.toml | toml-get "plugin" "version")"
		local desc="$(cat $path/plugin.toml | toml-get "plugin" "description")"
		printf "  %-20s %-5s %-10s %s\n" "$plugin" "$version" "$status" "$desc"
	done
	shopt -u nullglob
}

trigger() {
	declare desc="Triggers hook in enabled plugins"
	declare hook="$1"; shift
	shopt -s nullglob
	for plugin in $PLUGIN_PATH/enabled/*; do
		eval "$(config-export $(basename $plugin))"
		[[ -x "$plugin/$hook" ]] && $plugin/$hook "$@"
	done
	shopt -u nullglob
	trigger-gateway $hook "$@"
}

enable() {
	declare desc="Enable a plugin"
	declare plugin="$1"
	mkdir -p "$PLUGIN_PATH/enabled"
	ln -fs "$PLUGIN_PATH/available/$plugin" "$PLUGIN_PATH/enabled/$plugin"
	reload-gateway
}

disable() {
	declare desc="Disable a plugin"
	declare plugin="$1"
	mkdir -p "$PLUGIN_PATH/enabled"
	rm "$PLUGIN_PATH/enabled/$plugin"
	reload-gateway
}

config-get() {
	declare desc="Get plugin configuration"
	declare plugin="$1" name="$2"
	cat "$PLUGIN_PATH/config.toml" | toml-get "$plugin" "$name"
}

config-export() {
	declare desc="Export plugin configuration"
	declare plugin="$1"
	cat "$PLUGIN_PATH/config.toml" | toml-export "$plugin"
}

config-set() {
	declare desc="Set plugin configuration"
	declare plugin="$1" name="$2" value="$3"
	echo -n "$value" | toml-set "$PLUGIN_PATH/config.toml" "$plugin" "$name"
}

init() {
	declare desc="Initialize an empty plugin path"
	mkdir -p "$PLUGIN_PATH"
	touch "$PLUGIN_PATH/config.toml"
	mkdir -p "$PLUGIN_PATH/enabled"
	mkdir -p "$PLUGIN_PATH/available"
	echo "Initialized empty Plugn plugin path in $PLUGIN_PATH"
}

_source() {
	declare desc="Source commands for sourcable plugins"
	shopt -s nullglob
	for plugin in $PLUGIN_PATH/enabled/*; do
		[[ -f "$plugin/$(basename $plugin).sh" ]] && echo "source $plugin/$(basename $plugin).sh"
	done
	shopt -u nullglob
}

main() {
	set -eo pipefail; [[ "$TRACE" ]] && set -x

	cmd-export version
	cmd-export install
	cmd-export uninstall
	cmd-export update
	cmd-export list
	cmd-export trigger
	cmd-export enable
	cmd-export disable
	cmd-export _source "source"
	cmd-export-ns config "Plugin configuration"
	cmd-export config-get
	cmd-export config-export
	cmd-export config-set
	cmd-export init

	cmd-ns "" "$@"
}
