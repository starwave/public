package main

import (
    "fmt"
    "github.com/kbinani/screenshot"
)

func main() {

 	n := screenshot.NumActiveDisplays()
 	fmt.Println(n)
 	for i := 0; i < n; i++ {
 		bounds := screenshot.GetDisplayBounds(i)
 		x := bounds.Dx()
 		y := bounds.Dy()
 		fmt.Printf("%dx%d\n", x, y)
 	}
}

/*
    // import "os"

    argsWithProg := os.Args
    argsWithoutProg := os.Args[1:]
    arg := os.Args[3]
    fmt.Println(argsWithProg)
    fmt.Println(argsWithoutProg)
    fmt.Println(arg)
*/
