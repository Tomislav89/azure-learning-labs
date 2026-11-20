package main

import (
    "fmt"
    "log"
    "net/http"
)

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintln(w, "Hello from Docker Multi-stage Build Lab!")
    })

    log.Println("Server listening on port 8080")

    log.Fatal(http.ListenAndServe(":8080", nil))
}
