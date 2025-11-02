package ngorongoro

import (
	"encoding/base64"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/starwave/golang/bputil"
)

// NgrongHTTPService is to maintain the main global objects.
type NgrongHTTPService struct {
	safeRotationCounter *bputil.SafeRotationCounter
	imageManager        *NgorongImageManager
}

// NewNgrongHTTPService is to create the new http service
func NewNgrongHTTPService() *NgrongHTTPService {
	ngs := new(NgrongHTTPService)
	ngs.safeRotationCounter = &bputil.SafeRotationCounter{Index: 0, MaxIndex: 40}
	if bputil.GetOSName() == "linux" {
		paths := []string{bputil.GetHomeDir() + "/CloudStation/BP Wallpaper", bputil.GetHomeDir() + "/Documents/CloudStation/Best"}
		ngs.imageManager = NewNgorongImageManager(paths)
	} else {
		paths := []string{bputil.GetHomeDir() + "/Downloads/Media/CloudStation"}
		ngs.imageManager = NewNgorongImageManager(paths)
	}
	return ngs
}

// StartService is to start the service
func (ngs *NgrongHTTPService) StartService() {
	log.Println("ngorongoro http service started.")
	ngs.createWallpaperDirectory()
	ngs.imageManager.StartImageManager()
	http.HandleFunc("/ngorongoro", ngs.handleNgorongoro)
	http.HandleFunc("/tromso", ngs.handleTromso)
	http.HandleFunc("/masai", ngs.handleMasai)
	http.HandleFunc("/maramboi", ngs.handleMaramboi)
	http.HandleFunc("/file-list", fileListHandler)
	http.HandleFunc("/file-list-ver", fileListVerHandler)
	http.HandleFunc("/file-download", fileDownloadHandler)
	http.HandleFunc("/tromso.png", ngs.faviconHandler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}

// _theme="special1"
// _dimention="origin"
// _optionstring=""
// curl -o ~/Desktop/zimage.jpg -sv "http://192.168.1.111:8080/ngorongoro?a=tweb&d=${_dimension}&t=${_theme}${_optionstring}&$(date +%s)" 2>&1 | grep "Coden:" | awk '{print $3}' | base64 -D
func (ngs *NgrongHTTPService) handleNgorongoro(w http.ResponseWriter, req *http.Request) {
	var index = ngs.safeRotationCounter.GetNextIndex()
	var fileName = fmt.Sprintf(".wallpapers/.ngorongoro%02d.jpg", index)
	log.Printf("[%s] \"%s %s %s\"",
		strings.Split(req.RemoteAddr, ":")[0],
		//time.Now().Format("02/Jan/2006:15:04:05 -07:00"),
		req.Method,
		req.URL.RequestURI(),
		req.Header.Get("User-Agent"),
		// req.Proto,
	)
	if err := req.ParseForm(); err != nil {
		log.Printf("Error parsing form: %s", err)
		return
	}
	dimension := req.Form.Get("d")
	theme := req.Form.Get("t")
	option := req.Form.Get("o")
	coden := ngs.getRandomImage(fileName, dimension, theme, option)
	log.Println("Ngorongoro: " + coden)
	for len(coden) > 0 && !bputil.FileExists(fileName) {
		time.Sleep(200)
	}
	img, err := os.Open(fileName)
	if err != nil {
		log.Println(err)
	} else {
		fi, err := os.Stat(fileName)
		if err != nil {
			log.Println(err)
		} else {
			// get the size
			size := fi.Size()
			encodedCoden := base64.StdEncoding.EncodeToString([]byte(coden))
			w.Header().Set("Coden", encodedCoden)
			w.Header().Set("Content-Type", "image/jpeg")
			w.Header().Set("Content-Length", strconv.FormatInt(size, 10))
			io.Copy(w, img)
		}
	}
	defer img.Close()
}

func (ngs *NgrongHTTPService) getRandomImage(fileName string, dimension string, theme string, option string) string {
	// -d origin will return original image
	if dimension == "origin" {
		option += " -d origin "
	} else if dimension != "" {
		option += " -D " + dimension
	}
	if theme != "" {
		option += " -t " + theme
	}
	bashcmd := "bpwallpaper -U '" + fileName + "'" + option
	stdout, err := bputil.BashCommand(bashcmd)
	if err != nil {
		log.Println(err)
		return ""
	}
	return stdout
}

func (ngs *NgrongHTTPService) createWallpaperDirectory() {
	stdout, err := bputil.BashCommand("mkdir -p .wallpapers; rm -rf .wallpapers/.*.jpg || true")
	if err != nil {
		log.Fatal(err)
	}
	log.Println(stdout)
}
