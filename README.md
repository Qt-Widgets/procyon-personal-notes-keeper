# Procyon

Procyon is personal note-keeping application. It is heavily inspired by Evernote and Microsoft OneNote and Google Keep but lacks the [fatal flow](http://www.drdobbs.com/windows/a-brief-history-of-windows-programming-r/225701475) of those :). It also lacks many of their abilities, of course, to be honest.

Procyon manages a set of text notes storing them in a single SQLite database. It doesn't use its own server, and to share the database between your machines, you are free to choose a favored sync service, e.g., Dropbox or Google Drive.

It supports syntax highlighting for some programming languages and custom highlighter for general working notes.

See [Releases](https://github.com/orion-project/procyon/releases) section for downloading binary package.

![Main Window](./img/main_window.png)

## Build and run

**Clone the repo**

```bash
git clone https://github.com/orion-project/procyon
cd procyon
git submodule init
git submodule update
```

**Prepare dependencies**

The project requires some third part dependecies. Follow these [instructions](deps/README.md) to prepare them.

**Build the project**

```bash
# Linux\macOS
./release/make_release.py

# Windows
release\make_release.py
```


**Run**

Target file is `bin/procyon` (Linux), `bin/procyon.app` (MacOS), or `bin\procyon.exe` (Windows).
