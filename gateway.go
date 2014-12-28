package main

import (
	"io"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"./coproc"
	"github.com/progrium/duplex/poc2/duplex"
)

func startGateway() {
	go serveGateway()
	outputlog, err := os.OpenFile(PluginPath+"/output.log", os.O_CREATE|os.O_RDWR|os.O_APPEND, 0660)
	if err != nil {
		log.Fatal(err)
	}
	coproc.StartCoprocs(findPlugins(), outputlog)
}

func findPlugins() []string {
	var plugins []string
	enabled, err := ioutil.ReadDir(PluginPath + "/enabled")
	if err != nil {
		log.Println(err)
		return []string{}
	}
	for _, file := range enabled {
		filepath := PluginPath + "/available/" + file.Name() + "/" + file.Name()
		if _, err := os.Stat(filepath); err == nil {
			plugins = append(plugins, filepath)
		}
	}
	return plugins
}

func serveGateway() {
	gateway := duplex.NewPeer()
	defer gateway.Shutdown()
	gateway.SetOption(duplex.OptName, "plugn:gateway")
	err := gateway.Bind("unix://" + PluginPath + "/gateway.sock")
	if err != nil {
		panic(err)
	}
	for {
		meta, ch := gateway.Accept()
		go func() {
			for _, peer := range gateway.Peers() {
				if !strings.HasPrefix(peer, "plugn") {
					hook, err := gateway.Open(peer, meta.Service(), meta.Headers())
					if err != nil {
						panic(err)
					}
					io.Copy(ch, hook)
					hook.Close()
				}
			}
			ch.Close()
		}()
	}
}

func TriggerGateway(args []string) int {
	gatewaySock := "unix://" + PluginPath + "/gateway.sock"
	if _, err := os.Stat(gatewaySock); os.IsNotExist(err) {
		return 0
	}
	trigger := duplex.NewPeer()
	defer trigger.Shutdown()
	trigger.SetOption(duplex.OptName, "plugn:trigger")
	err := trigger.Connect(gatewaySock)
	if err != nil {
		panic(err)
	}
	ch, err := trigger.Open("plugn:gateway", args[0], args[1:])
	if err != nil {
		panic(err)
	}
	io.Copy(os.Stdout, ch)
	ch.Close()
	return 0
}
