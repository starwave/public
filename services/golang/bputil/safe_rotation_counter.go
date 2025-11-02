package bputil

import (
    "sync"
)

type SafeRotationCounter struct {
	mutex sync.Mutex
	Index int
	MaxIndex int
}

func (c *SafeRotationCounter) GetNextIndex() int {
	c.mutex.Lock()
	c.Index = (c.Index + 1) % c.MaxIndex
	var return_index = c.Index
	defer c.mutex.Unlock()
	return return_index
}