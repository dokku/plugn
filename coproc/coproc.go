package coproc

import (
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"sync"
	"syscall"
	"time"
)

const shutdownGraceTime = 3 * time.Second

func sendSignal(pid int, signal syscall.Signal) error {
	group, err := os.FindProcess(-1 * pid)
	if err == nil {
		err = group.Signal(signal)
	}
	return err
}

func longestBase(paths []string) int {
	l := 0
	for _, s := range paths {
		if len(filepath.Base(s)) > l {
			l = len(filepath.Base(s))
		}
	}
	return l
}

type Coproc struct {
	outletFactory *OutletFactory

	teardown, teardownNow Barrier // signal shutting down

	wg sync.WaitGroup

	name string
}

func (f *Coproc) log(s string) {
	f.outletFactory.WriteLine(f.name, s, false)
	if f.outletFactory.Output != os.Stdout {
		log.Println(f.name + ": " + s)
	}
}

func (f *Coproc) monitorInterrupt() {
	handler := make(chan os.Signal, 1)
	signal.Notify(handler, os.Interrupt)

	first := true

	for sig := range handler {
		switch sig {
		case os.Interrupt:
			f.log("ctrl-c detected")

			f.teardown.Fall()
			if !first {
				f.teardownNow.Fall()
			}
			first = false
		}
	}
}

func (f *Coproc) startProcess(idx int, procPath string, env []string, of *OutletFactory) {
	ps := exec.Command(procPath)
	//ps.Dir = filepath.Dir(procPath)
	ps.Env = env
	procName := filepath.Base(procPath)
	//ps.Env["PORT"] = "5000"

	ps.Stdin = nil

	stdout, err := ps.StdoutPipe()
	if err != nil {
		panic(err)
	}
	stderr, err := ps.StderrPipe()
	if err != nil {
		panic(err)
	}

	pipeWait := new(sync.WaitGroup)
	pipeWait.Add(2)
	go of.LineReader(pipeWait, procName, idx, stdout, false)
	go of.LineReader(pipeWait, procName, idx, stderr, true)

	f.log(fmt.Sprintf("starting %s", procName))

	finished := make(chan struct{}) // closed on process exit

	err = ps.Start()
	if err != nil {
		f.teardown.Fall()
		f.log(fmt.Sprint("failed to start ", procName, ": ", err))
		return
	}

	f.wg.Add(1)
	go func() {
		defer f.wg.Done()
		defer close(finished)
		pipeWait.Wait()
		ps.Wait()
	}()

	f.wg.Add(1)
	go func() {
		defer f.wg.Done()

		// Prevent goroutine from exiting before process has finished.
		defer func() { <-finished }()
		defer f.teardown.Fall()

		select {
		case <-finished:
			time.Sleep(1 * time.Second) // for now, just in case loop
			f.log(fmt.Sprintf("restarting %s", procName))
			f.startProcess(idx, procPath, env, of)
			return

		case <-f.teardown.Barrier():
			// tearing down

			f.log(fmt.Sprintf("sending SIGTERM to %s", procName))
			sendSignal(ps.Process.Pid, syscall.SIGTERM)

			// Give the process a chance to exit, otherwise kill it.
			select {
			case <-f.teardownNow.Barrier():
				f.log(fmt.Sprintf("killing %s", procName))
				sendSignal(ps.Process.Pid, syscall.SIGKILL)
			case <-finished:
			}
		}
	}()
}

func StartCoprocs(procs []string, output io.Writer, name string) {
	of := NewOutletFactory()
	of.Padding = longestBase(procs)
	of.Output = output

	f := &Coproc{
		outletFactory: of,
		name:          name,
	}

	if len(procs) == 0 {
		f.log("no processes to run")
	}

	go f.monitorInterrupt()

	// When teardown fires, start the grace timer
	f.teardown.FallHook = func() {
		go func() {
			time.Sleep(shutdownGraceTime)
			f.log("grace time expired")
			f.teardownNow.Fall()
		}()
	}

	for idx, proc := range procs {
		f.startProcess(idx, proc, os.Environ(), of)
	}

	<-f.teardown.Barrier()

	f.wg.Wait()
}
