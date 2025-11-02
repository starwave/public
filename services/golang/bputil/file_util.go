package bputil

import (
    "os/user"
    "log"
    "os"
    "path/filepath"
)

func IsDirectory(path string) (bool, error) {
    fileInfo, err := os.Stat(path)
    if err != nil{
      return false, err
    }
    return fileInfo.IsDir(), err
}

func GetHomeDir() string {
    usr, err := user.Current()
    if err != nil {
        log.Fatal( err )
    }
    return usr.HomeDir
}

func GetOnlyFileName(path string) string {
    base := filepath.Base(path)
    return base
}

func GetFolderName(path string) string {
    dir := filepath.Dir(path)
    return dir
}

func FileExists(filename string) bool {
	info, err := os.Stat(filename)
	if os.IsNotExist(err) {
		return false
	}
	return !info.IsDir()
}