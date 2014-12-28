package coproc

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"sync"
)

type OutletFactory struct {
	Padding int
	Output  io.Writer

	sync.Mutex
}

func NewOutletFactory() (of *OutletFactory) {
	return new(OutletFactory)
}

func (of *OutletFactory) LineReader(wg *sync.WaitGroup, name string, index int, r io.Reader, isError bool) {
	defer wg.Done()

	reader := bufio.NewReader(r)

	var buffer bytes.Buffer

	for {
		buf := make([]byte, 1024)
		v, _ := reader.Read(buf)

		if v == 0 {
			return
		}

		idx := bytes.IndexByte(buf, '\n')
		if idx >= 0 {
			buffer.Write(buf[0:idx])
			of.WriteLine(name, buffer.String(), isError)
			buffer.Reset()
		} else {
			buffer.Write(buf)
		}
	}
}

// Write out a single coloured line
func (of *OutletFactory) WriteLine(left, right string, isError bool) {
	of.Lock()
	defer of.Unlock()

	formatter := fmt.Sprintf("%%-%ds | ", of.Padding)
	fmt.Fprintf(of.Output, formatter, left)
	fmt.Fprintln(of.Output, right)
}
