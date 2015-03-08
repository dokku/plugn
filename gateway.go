package main

import (
	"io"
	"io/ioutil"
	"log"
	"os"
	"os/signal"
	"strings"
	"sync"

	"github.com/progrium/duplex/poc2/duplex"
	"github.com/progrium/plugin-demo/demo/coproc"
)

func runGateway() {
	log.Println("starting gateway...")
	wg := new(sync.WaitGroup)
	host := coproc.StartHost(findPlugins())
	wg.Add(1)
	go func() {
		host.Wait()
		wg.Done()
	}()
	gateway := startGateway(wg, host)
	go func() {
		handler := make(chan os.Signal, 1)
		signal.Notify(handler, os.Interrupt)
		first := true
		for sig := range handler {
			switch sig {
			case os.Interrupt:
				log.Println("ctrl-c detected")
				gateway.Shutdown()
				host.Shutdown(!first)
				first = false
			}
		}
	}()
	wg.Wait()
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

func startGateway(wg *sync.WaitGroup, plugins *coproc.Host) *duplex.Peer {
	gateway := duplex.NewPeer()
	gateway.SetOption(duplex.OptName, "plugn:gateway")
	err := gateway.Bind("unix://" + PluginPath + "/gateway.sock")
	if err != nil {
		panic(err)
	}
	wg.Add(1)
	go func() {
		for {
			meta, ch := gateway.Accept()
			if meta == nil {
				break
			}
			if meta.Service() == "reload" {
				log.Println("reload received...")
				plugins.RestartWith(findPlugins())
				ch.Close()
				continue
			}
			go func() {
				for _, peer := range gateway.Peers() {
					if !strings.HasPrefix(peer, "plugn") {
						hook, err := gateway.Open(peer, meta.Service(), meta.Headers())
						if err != nil {
							log.Println("unable to trigger", peer)
							continue
						}
						io.Copy(ch, hook)
						hook.Close()
					}
				}
				ch.Close()
			}()
		}
		wg.Done()
	}()
	return gateway
}

func TriggerGateway(args []string) {
	gatewaySock := PluginPath + "/gateway.sock"
	if _, err := os.Stat(gatewaySock); os.IsNotExist(err) {
		return
	}
	trigger := duplex.NewPeer()
	defer trigger.Shutdown()
	trigger.SetOption(duplex.OptName, "plugn:trigger")
	err := trigger.Connect("unix://" + gatewaySock)
	if err != nil {
		panic(err)
	}
	ch, err := trigger.Open("plugn:gateway", args[0], args[1:])
	if err != nil {
		panic(err)
	}
	io.Copy(os.Stdout, ch)
	ch.Close()
}

func ReloadGateway(args []string) {
	gatewaySock := PluginPath + "/gateway.sock"
	if _, err := os.Stat(gatewaySock); os.IsNotExist(err) {
		return
	}
	trigger := duplex.NewPeer()
	defer trigger.Shutdown()
	trigger.SetOption(duplex.OptName, "plugn:reload")
	err := trigger.Connect("unix://" + gatewaySock)
	if err != nil {
		panic(err)
	}
	_, err = trigger.Open("plugn:gateway", "reload", nil)
	if err != nil {
		panic(err)
	}
}
