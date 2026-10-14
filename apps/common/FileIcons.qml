// The picture a file is shown with: itself when it is a picture, else its kind's icon from the system's icon set.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var kinds: ({ "image-x-generic": ["svg", "bmp", "ico", "tiff", "xcf"], "audio-x-generic": ["mp3", "flac", "ogg", "wav", "m4a", "opus"],
        "video-x-generic": ["mp4", "mkv", "webm", "mov", "avi"], "package-x-generic": ["zip", "gz", "xz", "tar", "7z", "rar", "bz2", "zst", "iso"],
        "application-pdf": ["pdf"], "x-office-document": ["odt", "doc", "docx", "rtf"], "x-office-spreadsheet": ["ods", "xls", "xlsx", "csv"],
        "x-office-presentation": ["odp", "ppt", "pptx"], "text-x-script": ["sh", "py", "lua", "js", "rs", "c", "cpp", "h", "json", "toml", "qml"],
        "application-x-executable": ["appimage", "exe", "run", "bin"], "text-html": ["html", "htm"] })
    readonly property var pictures: ["png", "jpg", "jpeg", "webp", "gif"]
    function ending(name) { const i = name.lastIndexOf("."); return i > 0 ? name.slice(i + 1).toLowerCase() : "" }
    function of(name, path, isDir) {
        if (isDir) return Quickshell.iconPath("folder", true)
        const e = ending(name)
        if (pictures.includes(e)) return "file://" + path
        for (const k in kinds) if (kinds[k].includes(e)) return Quickshell.iconPath(k, true)
        return Quickshell.iconPath("text-x-generic", true)
    }
}
