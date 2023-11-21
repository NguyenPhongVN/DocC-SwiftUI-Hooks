# ``DocCHooks``

### Generating Documentation for Extended Types


```
swift package --allow-writing-to-directory ./docs \
    generate-documentation --target DocCHooks --output-path ./docs
```

```
swift package --disable-sandbox preview-documentation --target DocCHooks
```

### Publishing to GitHub Pages

```
sudo swift package --allow-writing-to-directory ./docs \
    generate-documentation --target DocCHooks \
    --disable-indexing \
    --transform-for-static-hosting \
    --hosting-base-path DocC-SwiftUI-Hooks \
    --output-path ./docs

```

[Doc Hooks](https://nguyenphongvn.github.io/DocC-SwiftUI-Hooks/documentation/docchooks/)
