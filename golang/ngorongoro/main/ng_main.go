package main

import (
	"github.com/starwave/golang/ngorongoro"
)

// GET http://localhost:8080/ngorongoro?o=option_string

func main() {
	ng := ngorongoro.NewNgrongHTTPService()
	ng.StartService()
}
