package bputil

import (
    "time"
)

type CancellableTimer struct {
    cancel chan bool
}

func NewCancellableTimer() *CancellableTimer {
    return &CancellableTimer{
        cancel: make(chan bool),
    }
}

// internal wait goroutine wrapping time.After
func (c *CancellableTimer) wait(d time.Duration, ch chan bool) {
    select {
    case <-time.After(d):
        ch <- true
    case <-c.cancel:
        ch <- false
    }
}

// After mimics time.After but returns bool to signify whether we timed out or cancelled
func (c *CancellableTimer) After(d time.Duration) chan bool {
    ch := make(chan bool)
    go c.wait(d, ch)
    return ch
}

// Cancel makes all the waiters receive false
func (c *CancellableTimer) Cancel() {
    close(c.cancel)
}