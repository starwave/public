package bputil

import (
    "runtime"
    "os/exec"
    "log"
)

func GetOSName() string {
    if ( runtime.GOOS == "darwin" ) {
        return "osx"
    } else if ( runtime.GOOS == "linux" ) {
        return "linux"
    }  else if ( runtime.GOOS == "windows" ) {
        return "windows"
    } else {
        return "unknown"
    }
}

func BashCommand(cmd string) (string, error) {
    // echo := exec.Command("echo", os.Getenv("PATH"))
    log.Println("bash $ " + cmd)
	bashcmd := exec.Command("bash", "-c", cmd)
	stdout, err := bashcmd.Output()
    return string(stdout), err 
}