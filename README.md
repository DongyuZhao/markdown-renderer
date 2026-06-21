# markdown-renderer

Monorepo for optimized Markdown rendering packages across iOS, macOS, Android, and Web.

## Packages

- `packages/swift-markdown-render` (SPM package for iOS/macOS)
- `packages/compose-markdown` (Jetpack Compose package for Android)
- `packages/react-markdown` (React package for Web)

## Samples

- `samples/swift-markdown-render-sample` (Swift CLI sample for macOS)
- `samples/compose-markdown-sample` (Android app sample)
- `samples/react-markdown-sample` (Vite + React web sample)

## Quick start

### iOS/macOS (`swift-markdown-render`)

```bash
cd packages/swift-markdown-render
swift build
```

### Android (`compose-markdown`)

Import `packages/compose-markdown` as an Android library module in your Android project.

### Web (`react-markdown`)

```bash
cd packages/react-markdown
npm install
npm run build
```

## Running the sample apps

### iOS/macOS sample

```bash
cd samples/swift-markdown-render-sample
swift run
```

### Android sample

Open `samples/compose-markdown-sample` in Android Studio and run the `:app` target.

### Web sample

```bash
cd samples/react-markdown-sample
npm install
npm run dev   # start dev server
npm run build # production build
```

