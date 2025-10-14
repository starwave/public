package ngorongoro

import (
	"fmt"
	"log"
	"net/http"
	"strings"
)

func (ngs *NgrongHTTPService) handleMasai(w http.ResponseWriter, req *http.Request) {
	addr := strings.Split(req.RemoteAddr, ":")[0]
	log.Printf("[%s] \"%s %s %s\" Current Status: %s",
		addr,
		req.Method,
		req.URL.RequestURI(),
		req.Proto,
		ngs.imageManager.FSM.Current())
	ngs.imageManager.AddAddress(addr)
	ngs.imageManager.AddSyncDir(".");
	ngs.imageManager.FSM.Event("sync_request")
	fmt.Fprintf(w, "/masai requst from [%s] is accepted. status = %s", addr, ngs.imageManager.FSM.Current())
}

// AddAddress is to add IP address from requests
func (ngim *NgorongImageManager) AddAddress(addr string) {
	// 'all' option will override the individual ip rsync anyway within rsync_androids
	if ngim.addrs != "all" {
		if !strings.Contains(ngim.addrs, addr) {
			ngim.addrs += " " + addr
		}
	}
}
