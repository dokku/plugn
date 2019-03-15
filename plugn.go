package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/BurntSushi/toml"
	"github.com/progrium/go-basher"
)

var Version string
var PluginPath string

func assert(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func TomlGet(args []string) {
	bytes, err := ioutil.ReadAll(os.Stdin)
	assert(err)
	var t map[string]interface{}
	_, err = toml.Decode(string(bytes), &t)
	assert(err)
	fmt.Println(t[args[0]].(map[string]interface{})[args[1]])
}

func TomlExport(args []string) {
	plugin := args[0]
	bytes, err := ioutil.ReadAll(os.Stdin)
	assert(err)

	var c map[string]map[string]string
	_, err = toml.Decode(string(bytes), &c)
	assert(err)
	config := c[plugin]
	prefix := strings.ToUpper(strings.Replace(plugin, "-", "_", -1))

	var p map[string]map[string]interface{}
	_, err = toml.DecodeFile(PluginPath+"/available/"+plugin+"/plugin.toml", &p)
	assert(err)
	config_def := p["plugin"]["config"].(map[string]interface{})

	for key := range config_def {
		k := strings.ToUpper(strings.Replace(key, "-", "_", -1))
		fmt.Println("export CONFIG_" + k + "=\"${" + prefix + "_" + k + ":-\"" + config[key] + "\"}\"")
	}
}

func TomlSet(args []string) {
	bytes, err := ioutil.ReadAll(os.Stdin)
	assert(err)
	var t map[string]map[string]string
	_, err = toml.DecodeFile(args[0], &t)
	assert(err)
	if t[args[1]] == nil {
		t[args[1]] = make(map[string]string)
	}
	t[args[1]][args[2]] = string(bytes)
	f, err := os.Create(args[0])
	assert(err)
	assert(toml.NewEncoder(f).Encode(t))
	f.Close()
}

func main() {
	os.Setenv("PLUGN_VERSION", Version)
	if data, err := ioutil.ReadFile(".plugn"); err == nil {
		if path, err := filepath.Abs(string(data)); err == nil {
			os.Setenv("PLUGIN_PATH", path)
		}
	}
	if os.Getenv("PLUGIN_PATH") == "" {
		fmt.Println("!! PLUGIN_PATH is not set in environment")
		os.Exit(2)
	}
	PluginPath = os.Getenv("PLUGIN_PATH")
	if len(os.Args) > 1 && os.Args[1] == "gateway" {
		runGateway()
		return
	}
	funcs := map[string]func([]string){
		"toml-get":        TomlGet,
		"toml-set":        TomlSet,
		"toml-export":     TomlExport,
		"trigger-gateway": TriggerGateway,
		"reload-gateway":  ReloadGateway,
	}
	scripts := []string{
		"bashenv/bash.bash",
		"bashenv/fn.bash",
		"bashenv/cmd.bash",
		"bashenv/plugn.bash",
	}

	if os.Getenv("BASH_BIN") == "" {
		basher.Application(funcs, scripts, Asset, true)
	} else {
		basher.ApplicationWithPath(funcs, scripts, Asset, true, os.Getenv("BASH_BIN"))
	}
}
