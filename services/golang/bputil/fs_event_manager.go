package bputil

// "github.com/fsnotify/fsnotify" is up to date version
import (
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/starwave/golang/extern/fsnotify"
)

type FSEventManager struct {
	pathsToMonitor []string
	AllSubDirs     []string
	watcher        *fsnotify.Watcher
	doneMonitor    chan bool
	Callback       func(eventName string, path string, isDir bool)
}

func NewFSEventManager(paths []string) *FSEventManager {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Println("error in fsnotify.NewWatcher", err)
	}
	fsem := &FSEventManager{pathsToMonitor: paths, watcher: watcher}
	fsem.Callback = nil
	return fsem
}

func (fsem *FSEventManager) StartMonitor() {
	log.Println("Start Monitor")
	defer fsem.watcher.Close()
	fsem.doneMonitor = make(chan bool)
	go func() {
		for {
			select {
			case event, ok := <-fsem.watcher.Events:
				if !ok {
					return
				}
				if strings.HasPrefix(GetOnlyFileName(event.Name), ".") {
					return
				}
				op := event.Op.String()
				// log.Println(op + ":" + event.Name)
				added := false
				removed := false
				switch op {
				// Mac, Linux : Create new, Move into, Move within (New Dir, New File)
				case "CREATE":
					added = true
				// Mac, Linux : Move within, Move out of, Removed by Finder (Old File)
				// Linux : Move within, Move out of, Removed by Finder (Old Dir)
				case "RENAME":
					removed = true
				// Mac, Linux : Removed by Terminal (Old Dir, Old File)
				case "REMOVE":
					removed = true
				// Mac : Move within, Move out of, Removed by Finder (Old Dir)
				case "REMOVE|RENAME":
					removed = true
				// Mac : Edit files without being removed
				case "WRITE":
					// fsem.Callback("WRITE", event.Name, false)
				// Mac, Linux : Ignored
				case "CHMOD":
				default:
				}
				if removed || added {
					isDir, _ := IsDirectory(event.Name)
					// blindly check with AllSubDirs since it cannot check since already being removed
					if removed {
						for i, subPath := range fsem.AllSubDirs {
							if subPath == event.Name {
								fsem.AllSubDirs = append(fsem.AllSubDirs[:i], fsem.AllSubDirs[i+1:]...)
								fsem.watcher.Remove(subPath)
								isDir = true
								break
							}
						}
					}
					if isDir && added {
						if added {
							fsem.AllSubDirs = append(fsem.AllSubDirs, event.Name)
							fsem.watcher.Add(event.Name)
						}
					}
					if fsem.Callback != nil {
						if added {
							fsem.Callback("CREATE", event.Name, isDir)
						} else {
							fsem.Callback("REMOVE", event.Name, isDir)
						}

					}
					// log.Println("All Sub Dirs = ", fsem.AllSubDirs)
				}
			case err, ok := <-fsem.watcher.Errors:
				if !ok {
					return
				}
				log.Println("error:", err)
			}
		}
	}()
	// nil, append is allowed in golang
	// fsem.AllSubDirs = []string{}
	for _, path := range fsem.pathsToMonitor {
		err := fsem.addAllSubDirs(path)
		if err != nil {
			log.Fatal(err)
		}
	}
	if fsem.Callback != nil {
		fsem.Callback("READY", "", false)
	}
	// log.Println("All Sub Dirs = ", fsem.AllSubDirs)
	<-fsem.doneMonitor
	close(fsem.doneMonitor)
	log.Println("Stop Monitor")
}

func (fsem *FSEventManager) StopMonitor() {
	fsem.doneMonitor <- true
}

func (fsem *FSEventManager) addAllSubDirs(path string) error {
	err := filepath.Walk(path,
		func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if info.IsDir() {
				// skip hidden directory
				if strings.HasPrefix(GetOnlyFileName(path), ".") {
					return filepath.SkipDir
				}
				fsem.AllSubDirs = append(fsem.AllSubDirs, path)
				fsem.watcher.Add(path)
			}
			return nil
		})
	if err != nil {
		return err
	}
	return nil
}
