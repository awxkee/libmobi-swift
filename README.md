# libmobi

Libmob binding for `swift` for handle, azw3, mobi, azw4, azw files in swift for iOS, iPadOS, and MacOS

```swift
let mobi = try Mobi(url: URL()!)
let coverPage: Data? = try mobi.getCover()
let rawml = try mobi.getRawml()
// Dump html to destination url
try mobi.dumpRawml(dst: URL()!)
```
