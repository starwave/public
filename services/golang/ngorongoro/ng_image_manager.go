package ngorongoro

import (
	"encoding/json"
	"log"
	"os"
	"path"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/starwave/golang/bputil"
	"github.com/starwave/golang/extern/fsm"
)

// NgorongImageManager is main struct for server
type NgorongImageManager struct {
	ImagePaths           []string
	FSM                  *fsm.FSM
	platformFileObserver *bputil.FSEventManager
	timer                *bputil.CancellableTimer
	addrs                string
	cacheDone            bool
	reservedWordsDone    bool
	syncDirs             map[string]bool
}

// NewNgorongImageManager creates new ImageManager
func NewNgorongImageManager(paths []string) *NgorongImageManager {
	ngim := &NgorongImageManager{ImagePaths: paths}
	ngim.platformFileObserver = bputil.NewFSEventManager(paths)
	ngim.platformFileObserver.Callback = ngim.fileEventCallback
	ngim.addrs = ""
	ngim.cacheDone = true
	ngim.reservedWordsDone = true
	ngim.setFSM()
	ngim.syncDirs = make(map[string]bool)
	return ngim
}

func (ngim *NgorongImageManager) AddSyncDir(dir string) {
	sync_dir := strings.Replace(dir, "/Documents/CloudStation/Best", "/CloudStation/BP Photo", 1)
	ngim.syncDirs[sync_dir] = true
}

func (ngim *NgorongImageManager) fileEventCallback(event string, path string, isDir bool) {
	log.Printf("NgorongImageManager: event '%s', path = '%s'", event, path)
	// When file monitor started the first
	if event == "READY" {
		ngim.updateReservedWords()
		return
	}
	if ngim.timer != nil {
		ngim.timer.Cancel()
		ngim.timer = nil
	}
	image_root_dir := bputil.GetHomeDir()
	if bputil.GetOSName() == "osx" || bputil.GetOSName() == "windows" {
		image_root_dir += "/Downloads/Media"
	}
	dir := strings.Replace(bputil.GetFolderName(path), image_root_dir, "", 1)
	// if directory is updated, add top folder to sync. change "Best" to "BP Photo" will happen in rsync_androids
	if isDir {
		if strings.HasPrefix(dir, "/Documents/CloudStation/Best") {
			ngim.AddSyncDir("/Documents/CloudStation/Best")
		} else if strings.HasPrefix(dir, "/CloudStation/BP Wallpaper") {
			ngim.AddSyncDir("/CloudStation/BP Wallpaper")
		}
		// store directory for rsync_android if that is not top root path for monitoring.
	} else if dir != "/Documents/CloudStation/Best" && dir != "/CloudStation/BP Wallpaper" {
		ngim.AddSyncDir(dir)
	}
	// "CREATE" event besides "REMOVE" event should also delete existing caches (if any)
	// because dscloud does not issue "REMOVE" or "WRITE" if it has a file change during the sync pasue
	// bpcache takes care of checking cache existence and does not delete original path but only cache
	// directory update shouldn't trigger cache removal.
	if !isDir && (event == "REMOVE" || event == "CREATE") {
		bashCommand := "bpcache -m delete \"" + path + "\" 2>&1 | timestamp.sh | tee /dev/tty >> " + bputil.GetHomeDir() + "/logs/ngorongoro.log"
		if bputil.GetOSName() == "osx" || bputil.GetOSName() == "windows" {
			bashCommand = "echo -e 'bpcache -m delete \"" + path + "\" started'"
			_, err := bputil.BashCommand(bashCommand)
			if err != nil {
				log.Fatal(err)
			}
		} else {
			_, err := bputil.BashCommand(bashCommand)
			if err != nil {
				log.Fatal(err)
			}
		}
	}
	ngim.addrs = "all"
	ngim.cacheDone = false
	if isDir {
		ngim.reservedWordsDone = false
	}
	ngim.FSM.Event("file_change")
}

// StartImageManager is to start monitor
func (ngim *NgorongImageManager) StartImageManager() {
	go ngim.platformFileObserver.StartMonitor()
}

// StopImageManager is to stop monitor
func (ngim *NgorongImageManager) StopImageManager() {
	ngim.platformFileObserver.StopMonitor()
}

func (ngim *NgorongImageManager) setFSM() {
	ngim.FSM = fsm.NewFSM(
		"idle",
		fsm.Events{
			{Name: "file_change", Src: []string{"idle", "buffering"}, Dst: "buffer"},
			{Name: "sync_request", Src: []string{"idle"}, Dst: "process"},
			{Name: "timer_started", Src: []string{"buffer"}, Dst: "buffering"},
			{Name: "timer_elapsed", Src: []string{"buffering"}, Dst: "process"},
			{Name: "file_change", Src: []string{"process", "rsync"}, Dst: "queued"},
			{Name: "sync_request", Src: []string{"process"}, Dst: "queued"},
			{Name: "done", Src: []string{"process"}, Dst: "rsync"},
			{Name: "done", Src: []string{"rsync"}, Dst: "idle"},
			{Name: "done", Src: []string{"queued"}, Dst: "process"},
		},
		fsm.Callbacks{
			"enter_state": func(e *fsm.Event) {
				ngim.enterState(e)
			},
		},
	)
}

func (ngim *NgorongImageManager) enterState(e *fsm.Event) {
	log.Printf("NgorongImageManager: State (%s)\n", e.Dst)
	switch e.Dst {
	case "idle":
		ngim.timer = nil
	case "buffer":
		ngim.timer = bputil.NewCancellableTimer()
		go ngim.FSM.Event("timer_started")
	case "buffering":
		if ngim.timer != nil {
			timedOut := <-ngim.timer.After(time.Second * 40)
			if timedOut {
				go ngim.FSM.Event("timer_elapsed")
			}
		}
	case "process":
		ngim.timer = nil
		go ngim.processFileChange()
	case "rsync":
		go ngim.rsyncToAndroid()
	case "queued":
	default:
	}
}

func (ngim *NgorongImageManager) processFileChange() {
	if !ngim.cacheDone {
		// set the flag the first to handle any upcoming file change event during cache process
		ngim.cacheDone = true
		ngim.executeBPCache()
	}
	if !ngim.reservedWordsDone {
		// set the flag the first to handle any upcoming file change event during directory reserved words update
		ngim.reservedWordsDone = true
		ngim.updateReservedWords()
	}
	ngim.FSM.Event("done")
}

func (ngim *NgorongImageManager) rsyncToAndroid() {
	ngim.androidSync()
	ngim.FSM.Event("done")
}

func (ngim *NgorongImageManager) androidSync() {
	// copy paths buffer to paths to handle and create new buffer for upcoming changes
	paths := ngim.syncDirs
	ngim.syncDirs = make(map[string]bool)
	// iterate all paths in pathsBuffer
	path_parm := ""
	for path := range paths {
		path_parm += "-f \"" + path + "\" "
	}
	log.Println("NgorongImageManager: androidSync paths = " + path_parm)
	bashCommand := "rsync_androids " + path_parm + ngim.addrs + " 2>&1 | timestamp.sh | tee /dev/tty >> " + bputil.GetHomeDir() + "/logs/ngorongoro.log"
	ngim.addrs = ""
	if bputil.GetOSName() == "osx" || bputil.GetOSName() == "windows" {
		bashCommand = "echo -e 'rsync_androids started' with " + path_parm
	}
	_, err := bputil.BashCommand(bashCommand)
	if err != nil {
		log.Fatal(err)
	}
	// update FileList json
	result := ExtractParentPaths(paths, "/CloudStation")
	for _, path := range result {
		rel_path := strings.Replace(path, "/CloudStation/", "", 1)
		log.Printf("update file list at '%s'", rel_path)
		generateFileList(rel_path)
	}
}

func (ngim *NgorongImageManager) executeBPCache() {
	bashCommand := "bpcache -d all 2>&1 | timestamp.sh | tee /dev/tty >> " + bputil.GetHomeDir() + "/logs/ngorongoro.log"
	if bputil.GetOSName() == "osx" || bputil.GetOSName() == "windows" {
		bashCommand = "echo -e 'bpcache started'"
	}
	_, err := bputil.BashCommand(bashCommand)
	if err != nil {
		log.Fatal(err)
	}
}

func (ngim *NgorongImageManager) GetAllSubDirs() []string {
	allSubDirs := []string{}
	for _, path := range ngim.platformFileObserver.AllSubDirs {
		path = strings.Replace(path, bputil.GetHomeDir()+"/Documents/CloudStation/Best", "/BP Photo", 1)
		path = strings.Replace(path, bputil.GetHomeDir()+"/CloudStation/BP Wallpaper", "/BP Wallpaper", 1)
		allSubDirs = append(allSubDirs, path)
	}
	return allSubDirs
}

// reservedWords is the struct to hold reserved words information
type ReservedWord struct {
	Word     string
	WordPath string
}

func (ngim *NgorongImageManager) updateReservedWords() {
	log.Println("updateReservedWords started")
	if bputil.GetOSName() == "osx" || bputil.GetOSName() == "windows" {
		return
	}
	reservedWords := []ReservedWord{
		{
			Word:     "/",
			WordPath: "/",
		},
		{
			Word:     "#sn#",
			WordPath: "",
		},
		{
			Word:     "#nd#",
			WordPath: "",
		},
	}
	allSubDirs := ngim.GetAllSubDirs()
	for _, subPath := range allSubDirs {
		base := "/" + path.Base(subPath) + "/"
		reservedWord := new(ReservedWord)
		reservedWord.Word = base
		reservedWord.WordPath = subPath
		reservedWords = append(reservedWords, *reservedWord)
	}
	sort.Slice(reservedWords, func(i, j int) bool {
		return reservedWords[i].Word < reservedWords[j].Word
	})
	newreservedWordJSON, err := json.MarshalIndent(reservedWords, "", "\t")
	if err != nil {
		log.Println("error: MarshalIndent - ", err)
	}
	err = os.WriteFile(reservedWordsPath, newreservedWordJSON, 0644)
	if err != nil {
		log.Println(err)
	}
}

func ExtractParentPaths(paths map[string]bool, rootPath string) []string {
	pathSet := make(map[string]struct{})
	var result []string
	result = append(result, rootPath+"/")
	for fullPath := range paths {
		if !strings.HasPrefix(fullPath, rootPath) {
			continue
		}
		relativePath := strings.TrimPrefix(fullPath, rootPath)
		if strings.HasPrefix(relativePath, string(filepath.Separator)) {
			relativePath = relativePath[1:]
		}
		components := strings.Split(relativePath, string(filepath.Separator))
		for i := 1; i <= len(components); i++ {
			parentPath := filepath.Join(rootPath, strings.Join(components[:i], string(filepath.Separator)))
			if _, exists := pathSet[parentPath]; !exists {
				pathSet[parentPath] = struct{}{}
				result = append(result, parentPath)
			}
		}
	}
	return result
}
