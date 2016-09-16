package main

import (
	"io"
	"log"
	"os"

	"github.com/dokku/duplex/poc2/duplex"
)

func main() {
	plugin := duplex.NewPeer()
	defer plugin.Shutdown()
	plugin.SetOption(duplex.OptName, "remote")
	err := plugin.Connect("unix://" + os.Getenv("PLUGIN_PATH") + "/gateway.sock")
	if err != nil {
		panic(err)
	}
	log.Println("remote: starting...")
	for {
		meta, ch := plugin.Accept()
		log.Println("remote: triggered:", meta.Service(), meta.Headers())
		switch meta.Service() {
		case "items":
			io.WriteString(ch, "Fake Remote, Item 1:5.00\n")
			io.WriteString(ch, "Fake Remote, Item 2:5.00\n")
		}
		ch.Close()
	}
}
