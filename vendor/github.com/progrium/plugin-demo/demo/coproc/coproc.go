package coproc

import (
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"syscall"
	"time"
)

type Host struct {
	sync.Mutex
	closing, restart bool
	ps               map[string]*exec.Cmd
	wg               sync.WaitGroup
}

func (h *Host) runProcess(path string) {
	procName := filepath.Base(path)

	h.wg.Add(1)
	defer h.wg.Done()

	for h.restart {
		proc := exec.Command(path)
		proc.Stdin = nil
		proc.Stdout = os.Stdout
		proc.Stderr = os.Stderr
		h.Lock()
		h.ps[procName] = proc
		h.Unlock()
		log.Println("starting:", procName)
		err := proc.Start()
		if err != nil {
			log.Println("failed to start ", procName, ": ", err)
			return
		}
		proc.Wait()
		if !h.restart {
			break
		}
		time.Sleep(1 * time.Second)
	}
}

func (h *Host) closeProcesses() {
	h.Lock()
	defer h.Unlock()
	for name, proc := range h.ps {
		log.Println("sending SIGINT to", name)
		proc.Process.Signal(syscall.SIGINT)
		go func() {
			time.Sleep(1 * time.Second)
			if !proc.ProcessState.Exited() {
				log.Println("sending SIGKILL to uninterruptable", name)
				proc.Process.Signal(syscall.SIGKILL)
			}
		}()
	}
}

func (h *Host) killProcesses() {
	h.Lock()
	defer h.Unlock()
	for name, proc := range h.ps {
		log.Println("sending SIGKILL to", name)
		proc.Process.Signal(syscall.SIGKILL)
	}
}

func (h *Host) Restart() {
	h.closeProcesses() // runProcess restarts them
}

func (h *Host) RestartWith(procs []string) {
	h.Lock()
	h.restart = false
	h.Unlock()
	h.Restart()
	h.wg.Wait()
	h.boot(procs)
}

func (h *Host) Shutdown(force bool) {
	h.Lock()
	h.closing = true
	h.restart = false
	h.Unlock()
	if force {
		h.killProcesses()
	} else {
		h.closeProcesses()
	}
}

func (h *Host) Wait() {
	for !h.closing {
		h.wg.Wait()
	}
}

func (h *Host) boot(procs []string) {
	h.Lock()
	h.closing = false
	h.restart = true
	h.ps = make(map[string]*exec.Cmd)
	h.Unlock()
	for _, proc := range procs {
		go h.runProcess(proc)
	}
}

func StartHost(procs []string) *Host {
	h := &Host{ps: make(map[string]*exec.Cmd)}
	h.boot(procs)
	return h
}
