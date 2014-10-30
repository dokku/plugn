package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"github.com/BurntSushi/toml"
	"github.com/progrium/go-basher"
)

func assert(err error) {
	if err != nil {
		log.Fatal(err)
	}
}

func TomlGet(args []string) int {
	bytes, err := ioutil.ReadAll(os.Stdin)
	assert(err)
	var t map[string]interface{}
	_, err = toml.Decode(string(bytes), &t)
	assert(err)
	fmt.Println(t[args[0]].(map[string]interface{})[args[1]])
	return 0
}

func TomlExport(args []string) int {
	plugin := args[0]
	bytes, err := ioutil.ReadAll(os.Stdin)
	assert(err)

	var c map[string]map[string]string
	_, err = toml.Decode(string(bytes), &c)
	assert(err)
	config := c[plugin]
	prefix := strings.ToUpper(strings.Replace(plugin, "-", "_", -1))

	var p map[string]map[string]interface{}
	_, err = toml.DecodeFile(os.Getenv("PLUGIN_PATH")+"/available/"+plugin+"/plugin.toml", &p)
	assert(err)
	config_def := p["plugin"]["config"].(map[string]interface{})

	for key := range config_def {
		k := strings.ToUpper(strings.Replace(key, "-", "_", -1))
		fmt.Println("export CONFIG_" + k + "=\"${" + prefix + "_" + k + ":-\"" + config[key] + "\"}\"")
	}
	return 0
}

func TomlSet(args []string) int {
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
	return 0
}

func main() {
	bash := basher.NewContext()
	bash.ExportFunc("toml-get", TomlGet)
	bash.ExportFunc("toml-set", TomlSet)
	bash.ExportFunc("toml-export", TomlExport)
	bash.HandleFuncs(os.Args)

	if os.Getenv("DEV") == "1" {
		bash.Source("./bashenv/bash.bash")
		bash.Source("./bashenv/fn.bash")
		bash.Source("./bashenv/cmd.bash")
		bash.Source("./bashenv/plugn.bash")
	} else {
		f, err := ioutil.TempFile("", "plugn-bashenv")
		assert(err)
		data, err := bashenv()
		assert(err)
		f.Write(data)
		f.Close()
		bash.Source(f.Name())
		defer os.Remove(f.Name())
	}
	status, err := bash.Run("main", os.Args[1:])
	assert(err)
	os.Exit(status)
}
