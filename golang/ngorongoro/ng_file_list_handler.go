package ngorongoro

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/starwave/golang/bputil"
)

var fileDir = bputil.GetHomeDir() + "/CloudStation/"
var cacheDir = bputil.GetHomeDir() + "/ngorongoro_cache"

type ServerFile struct {
	Path         string `json:"p"`
	ModifiedDate string `json:"m"`
	FileSize     int64  `json:"s"`
}

func generateFileList(topFolder string) error {
	var fileInfos []ServerFile
	err := filepath.Walk(fileDir+topFolder, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			if strings.HasPrefix(info.Name(), ".") {
				return filepath.SkipDir
			}
			return nil
		}
		relPath, err := filepath.Rel(fileDir, path)
		if err != nil {
			return err
		}
		modifiedDate, fileSize, err := getFileInfo(path)
		if err == nil && fileSize != 0 && !strings.HasPrefix(filepath.Base(relPath), ".") {
			fileInfos = append(fileInfos, ServerFile{
				Path:         relPath,
				ModifiedDate: modifiedDate.Format("2006-01-02T15:04:05Z07:00"),
				FileSize:     fileSize,
			})
		}
		return nil
	})
	if err != nil {
		return err
	}
	if err := os.MkdirAll(cacheDir, os.ModePerm); err != nil {
		return err
	}
	var cacheFileName = getCacheFileName(topFolder)
	file, err := os.Create(filepath.Join(cacheDir, cacheFileName))
	if err != nil {
		return err
	}
	defer file.Close()
	write_cacheFile_info(cacheFileName)
	encoder := json.NewEncoder(file)
	return encoder.Encode(fileInfos)
}

func write_cacheFile_info(cacheFileName string) {
	kvs, err := NewKeyValueStore()
	if err != nil {
		log.Fatal(err)
	}
	defer kvs.Close()
	currentTime := time.Now().Format(time.RFC3339)
	log.Printf("%s is generated on %s", cacheFileName, currentTime)
	err = kvs.Put(cacheFileName, currentTime)
	if err != nil {
		log.Fatal(err)
	}
}

func read_cacheFile_info(cacheFileName string) (string, error) {
	kvs, err := NewKeyValueStore()
	if err != nil {
		log.Fatal(err)
	}
	defer kvs.Close()
	value, err := kvs.Get(cacheFileName)
	if err != nil {
		return "", err
	}
	return value, nil
}

func getCacheFileName(folder string) string {
	return "NG_" + strings.ReplaceAll(folder, "/", "_") + ".json"
}

func fileListHandler(w http.ResponseWriter, req *http.Request) {
	topFolder := req.URL.Query().Get("p")
	addr := strings.Split(req.RemoteAddr, ":")[0]
	log.Printf("[%s] fileListHandler: p = '%s'", addr, topFolder)
	enforceRefresh := req.URL.Query().Get("f")
	cacheFilePath := filepath.Join(cacheDir, getCacheFileName(topFolder))
	if _, err := os.Stat(cacheFilePath); os.IsNotExist(err) || enforceRefresh == "1" {
		if err := generateFileList(topFolder); err != nil {
			http.Error(w, "Error generating file list", http.StatusInternalServerError)
			return
		}
	}
	file, err := os.Open(cacheFilePath)
	if err != nil {
		http.Error(w, "Error reading cache file", http.StatusInternalServerError)
		return
	}
	defer file.Close()

	w.Header().Set("Content-Type", "application/json")
	_, err = io.Copy(w, file)
	if err != nil {
		http.Error(w, "Error sending file list", http.StatusInternalServerError)
	}
}

func fileListVerHandler(w http.ResponseWriter, req *http.Request) {
	topFolder := req.URL.Query().Get("p")
	addr := strings.Split(req.RemoteAddr, ":")[0]
	log.Printf("[%s] fileListVerHandler: p = '%s'", addr, topFolder)
	var cacheFileName = getCacheFileName(topFolder)
	value, err := read_cacheFile_info(cacheFileName)
	if err != nil {
		fmt.Fprintf(w, "none")
		return
	}
	fmt.Fprintf(w, "%s", value)
}

func getFileInfo(filepath string) (time.Time, int64, error) {
	fileInfo, err := os.Stat(filepath)
	if err != nil {
		return time.Time{}, 0, err
	}
	return fileInfo.ModTime(), fileInfo.Size(), nil
}

func fileDownloadHandler(w http.ResponseWriter, req *http.Request) {
	filePath := req.URL.Query().Get("f")
	addr := strings.Split(req.RemoteAddr, ":")[0]
	log.Printf("[%s] fileDownloadHandler: path = %s", addr, filePath)
	if filePath == "" {
		http.Error(w, "File path is required", http.StatusBadRequest)
		return
	}

	baseDir := filepath.Join(os.Getenv("HOME"), "CloudStation")
	fullPath := filepath.Join(baseDir, filePath)
	//log.Println("fileDownloadHandler: local full path = " + fullPath + " " + filepath.Base(fullPath))
	file, err := os.Open(fullPath)
	if err != nil {
		log.Println("fileDownloadHandler: file not found = " + fullPath)
		http.Error(w, "File not found", http.StatusNotFound)
		return
	}
	defer file.Close() // Ensure the file is closed properly.

	// Set headers for file download.
	w.Header().Set("Content-Disposition", "attachment; filename="+filepath.Base(fullPath))
	w.Header().Set("Content-Type", "application/octet-stream")

	// Write the file content to the response.
	if _, err := io.Copy(w, file); err != nil {
		log.Println("fileDownloadHandler: error writing file = " + fullPath + ", error: " + err.Error())
		// At this point, response headers have already been sent, so you can't call http.Error.
		// Log the error instead.
		return
	}
}
