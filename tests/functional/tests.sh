
plugn-test-pass() {
	declare name="$1" script="$2"
	docker run $([[ "$CI" ]] || echo "--rm") -v "$PWD:/mnt" \
		"plugn:dev" bash -c "set -e; export PLUGIN_PATH=/var/lib/plugins; $script" \
		|| $T_fail "$name exited non-zero"
}

plugn-test-fail() {
	declare name="$1" script="$2"
	docker run $([[ "$CI" ]] || echo "--rm") -v "$PWD:/mnt" \
		"plugn:dev" bash -c "set -e; export PLUGIN_PATH=/var/lib/plugins; $script" \
		|| echo "$name exited non-zero (as expected)"
}

fn-source() {
	# use this if you want to write tests
	# in functions instead of strings.
	# see test-binary for trivial example
	declare -f $1 | tail -n +2
}

T_binary() {
	_test-binary() {
		PLUGIN_PATH=/var/lib/plugins plugn
	}
	plugn-test-pass "test-binary" "$(fn-source _test-binary)"
}

T_plugn-config() {
	plugn-test-pass "test-config" "
		plugn init && \
		plugn install https://github.com/dokku/smoke-test-plugin && \
		plugn config export smoke-test-plugin"
}

T_plugn-init() {
	plugn-test-pass "test-init" "
		plugn init"
}

T_plugn-install-enable-disable() {
	plugn-test-pass "test-install-enable-disable" "
		plugn init && \
		plugn install https://github.com/dokku/smoke-test-plugin && \
		plugn enable smoke-test-plugin && \
		plugn list | grep enabled | grep smoke-test-plugin && \
		plugn disable smoke-test-plugin && \
		plugn list | grep disabled | grep smoke-test-plugin"
}

T_plugn-install-enable-disable-targz() {
	plugn-test-pass "test-install-enable-disable" "
		plugn init && \
		plugn install https://github.com/dokku/smoke-test-plugin/archive/v0.3.0.tar.gz smoke-test-plugin && \
		plugn enable smoke-test-plugin && \
		plugn list | grep enabled | grep smoke-test-plugin && \
		plugn disable smoke-test-plugin && \
		plugn list | grep disabled | grep smoke-test-plugin"
}

T_plugn-trigger() {
	plugn-test-pass "test-trigger" "
		plugn init && \
		plugn install https://github.com/dokku/smoke-test-plugin && \
		plugn update smoke-test-plugin v0.3.0 && \
		plugn enable smoke-test-plugin && \
		plugn list && \
		plugn trigger trigger | grep 'triggered smoke-test-plugin'"
}

T_plugn-uninstall() {
	plugn-test-fail "test-uninstall" "
		plugn init && \
		plugn install https://github.com/dokku/smoke-test-plugin && \
		plugn enable smoke-test-plugin && \
		plugn list | grep enabled | grep smoke-test-plugin && \
		plugn uninstall smoke-test-plugin && \
		plugn list | grep smoke-test-plugin"
}

T_plugn-update() {
	plugn-test-pass "test-update" "
		plugn init && \
		plugn install https://github.com/dokku/smoke-test-plugin && \
		plugn list | grep smoke-test-plugin && \
		plugn update smoke-test-plugin v0.2.0 && \
		plugn list | grep smoke-test-plugin | grep 0.2.0 && \
		plugn update smoke-test-plugin testing-branch-do-not-delete && \
		plugn list | grep smoke-test-plugin | grep 0.3.0-testing"
}

T_plugn-version() {
	plugn-test-pass "test-version" "
		plugn init && \
		plugn version"
}
