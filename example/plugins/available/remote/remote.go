package main

import (
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/progrium/duplex/poc2/duplex"
)

func main() {
	plugin := duplex.NewPeer()
	defer plugin.Shutdown()
	plugin.SetOption(duplex.OptName, "remote")
	err := plugin.Connect("unix://" + os.Getenv("PLUGIN_PATH") + "/gateway.sock")
	if err != nil {
		panic(err)
	}
	fmt.Println("starting...")
	for {
		meta, ch := plugin.Accept()
		fmt.Println("triggered:", meta.Service(), meta.Headers())
		args := strings.Join(meta.Headers(), " ")
		io.WriteString(ch, "Hello world from remote. Args: "+args+"\n")
		ch.Close()
	}
}
