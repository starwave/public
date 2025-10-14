package ngorongoro

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"sort"
	"strings"

	"github.com/starwave/golang/bputil"
)

// ThemeLib is the struct to hold theme information
type ThemeLib struct {
	Label  string
	Config string
}

var themelibPath = bputil.GetHomeDir() + "/Documents/CloudStation/Install/Docs/themelib.txt"
var reservedWordsPath = bputil.GetHomeDir() + "/Documents/CloudStation/Install/Docs/reservedwords.txt"

func (ngs *NgrongHTTPService) handleMaramboi(w http.ResponseWriter, req *http.Request) {
	addr := strings.Split(req.RemoteAddr, ":")[0]
	log.Printf("[%s] \"%s %s %s\" Current Status: %s",
		addr,
		req.Method,
		req.URL.RequestURI(),
		req.Proto,
		ngs.imageManager.FSM.Current())
	log.Println(req.URL.RequestURI() + " requst from [" + addr + "] is accepted.")
	if err := req.ParseForm(); err != nil {
		log.Printf("Error parsing form: %s", err)
		return
	}
	command := req.Form.Get("a")
	if command == "g" {
		ngs.readThemeLibFromFile(w)
	} else if command == "u" {
		label := req.Form.Get("l")
		config := req.Form.Get("c")
		ngs.updateThemeLib(w, label, config)
	} else if command == "r" {
		ngs.readReservedWordsFromFile(w)
	}
}

func (ngs *NgrongHTTPService) readThemeLibFromFile(w http.ResponseWriter) {
	content, err := os.ReadFile(themelibPath)
	if err != nil {
		log.Print(err)
	}
	// following will allow tromso web can get the themelib json file
	w.Header().Set("Access-Control-Allow-Origin", "*")
	// charset should be specified since some client lib (ex. android volley) refers it.
	// without it, it seems its own default like utf16
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	themelibJSON := string(content)
	fmt.Fprint(w, themelibJSON)
}

func (ngs *NgrongHTTPService) updateThemeLib(w http.ResponseWriter, label string, config string) {
	content, err := ioutil.ReadFile(themelibPath)
	if err != nil {
		log.Fatal(err)
	}
	themelibJSON := string(content)
	var themeLibs []ThemeLib
	var found = false
	json.Unmarshal([]byte(themelibJSON), &themeLibs)
	for i, themeLib := range themeLibs {
		if themeLib.Label == label {
			if config != "" {
				// update entry
				themeLib.Config = config
				themeLibs[i] = themeLib
			} else {
				// delete entry
				copy(themeLibs[i:], themeLibs[i+1:])
				themeLibs[len(themeLibs)-1] = ThemeLib{}
				themeLibs = themeLibs[:len(themeLibs)-1]
			}
			found = true
			break
		}
	}
	if !found {
		// add entry
		themeLib := new(ThemeLib)
		themeLib.Label = label
		themeLib.Config = config
		themeLibs = append(themeLibs, *themeLib)
	}
	sort.Slice(themeLibs, func(i, j int) bool {
		return themeLibs[i].Label < themeLibs[j].Label
	})
	newThemelibJSON, err := json.MarshalIndent(themeLibs, "", "\t")
	if err != nil {
		fmt.Println("error: MarshalIndent - ", err)
	}
	ngs.writeThemeLibToFile(newThemelibJSON)
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	fmt.Fprintf(w, "%s", newThemelibJSON)
}

func (ngs *NgrongHTTPService) writeThemeLibToFile(data []byte) {
	err := ioutil.WriteFile(themelibPath, data, 0644)
	if err != nil {
		log.Println(err)
	}
}

func (ngs *NgrongHTTPService) readReservedWordsFromFile(w http.ResponseWriter) {
	content, err := ioutil.ReadFile(reservedWordsPath)
	if err != nil {
		log.Print(err)
	}
	reservedWordsJSON := string(content)
	w.Header().Set("Content-Type", "application/json; charset=UTF-8")
	fmt.Fprint(w, reservedWordsJSON)
}
