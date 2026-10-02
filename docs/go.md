---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# Go formatting with gofmt

immosquare-cleaner formats Go files with `gofmt -s`, the formatter shipped with the Go toolchain. This page covers what gofmt changes, why Go files keep their tab indentation when every other format uses 2 spaces, and which Go files are left alone.

## What gofmt -s changes in a Go file

Every `.go` file goes through `gofmt -s -w`. Besides the canonical gofmt layout (spacing, blank lines between declarations, import formatting), the `-s` flag applies gofmt's simplifications: redundant types in composite literals are dropped (`[]P{P{1, 2}}` becomes `[]P{{1, 2}}`) and `s[a:len(s)]` becomes `s[a:]`.

```diff
 package main
+
 import "fmt"
-type P struct{X,Y int}
-func main(){
-  ps:=[]P{P{1,2},P{3,4}}
-  s:="hello"
-    fmt.Println(ps,s[1:len(s)])
+
+type P struct{ X, Y int }
+
+func main() {
+	ps := []P{{1, 2}, {3, 4}}
+	s := "hello"
+	fmt.Println(ps, s[1:])
 }
```

On a syntax error, gofmt prints its message and the file is left untouched.

## Why Go files keep tab indentation

immosquare-cleaner indents every other format with 2 spaces, but Go files keep gofmt's tabs. gofmt has no option to change its indentation: tabs are part of Go's canonical formatting. Converting them to spaces after gofmt would make gopls, editors and `gofmt -l` checks in CI report every file as unformatted, and the next `go fmt` would put the tabs back.

## Go files immosquare-cleaner leaves alone

`go.mod`, `go.work` and `go.sum` are not formatted. `go.sum` is a checksum list written by the `go` command, and every `go get` or `go mod tidy` already rewrites `go.mod` in its canonical layout. `go mod tidy` is deliberately never run: it adds and removes dependencies, which is not a formatter's job.

When a whole repository is cleaned, `testdata/` folders are skipped at any depth: Go test fixtures must stay exactly as written, and the Go toolchain ignores them too. `vendor/` is skipped as well.

Install Go, which provides gofmt, with `brew install go`. When gofmt is missing, immosquare-cleaner prints that command and leaves `.go` files as they are.
