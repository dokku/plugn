package main

import (
	"fmt"
	"github.com/progrium/duplex/poc2/duplex"
	"io"
	"os"
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
		fmt.Println(meta, ch)
		io.WriteString(ch, "Hello world from plugin4\n")
		ch.Close()
	}
}
