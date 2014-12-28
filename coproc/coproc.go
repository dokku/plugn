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
}

func (f *Coproc) monitorInterrupt() {
	handler := make(chan os.Signal, 1)
	signal.Notify(handler, os.Interrupt)

	first := true

	for sig := range handler {
		switch sig {
		case os.Interrupt:
			log.Println("plugn: ctrl-c detected")

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

	log.Println(fmt.Sprintf("plugn: starting %s", procName))

	finished := make(chan struct{}) // closed on process exit

	err = ps.Start()
	if err != nil {
		f.teardown.Fall()
		log.Println(fmt.Sprint("plugn: failed to start ", procName, ": ", err))
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
			f.startProcess(idx, procPath, env, of)
			return

		case <-f.teardown.Barrier():
			// tearing down

			log.Println(fmt.Sprintf("plugn: sending SIGTERM to %s", procName))
			sendSignal(ps.Process.Pid, syscall.SIGTERM)

			// Give the process a chance to exit, otherwise kill it.
			select {
			case <-f.teardownNow.Barrier():
				log.Println(fmt.Sprintf("plugn: killing %s", procName))
				sendSignal(ps.Process.Pid, syscall.SIGKILL)
			case <-finished:
			}
		}
	}()
}

func StartCoprocs(procs []string, output io.Writer) {
	of := NewOutletFactory()
	of.Padding = longestBase(procs)
	of.Output = output

	f := &Coproc{
		outletFactory: of,
	}

	go f.monitorInterrupt()

	// When teardown fires, start the grace timer
	f.teardown.FallHook = func() {
		go func() {
			time.Sleep(shutdownGraceTime)
			log.Println("plugn: grace time expired")
			f.teardownNow.Fall()
		}()
	}

	for idx, proc := range procs {
		f.startProcess(idx, proc, os.Environ(), of)
	}

	<-f.teardown.Barrier()

	f.wg.Wait()
}
