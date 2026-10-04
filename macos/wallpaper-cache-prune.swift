// Prune macOS wallpaper-agent BMP renders older than an hour. Shuffle writes a
// full-res uncompressed BMP per image per display (25-33 MB each, ~12 GB/day),
// never evicts them, and never reuses them. Pure cache: the agent re-renders.
//
// Single-purpose by design: this binary holds Full Disk Access (TCC blocks
// launchd jobs from other apps' containers), so path and policy are hard-coded
// and it takes no arguments. Built + signed + loaded by
// run_onchange_after_30-wallpaper-cache-prune.sh.tmpl.
import Foundation

let maxAge: TimeInterval = 60 * 60  // keep the last hour (~5 shuffles)
let cache = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
  "Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches/com.apple.wallpaper.caches")

let fm = FileManager.default
let cutoff = Date().addingTimeInterval(-maxAge)
let keys: Set<URLResourceKey> = [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]
var failed = false
var count = 0
var bytes = 0

func warn(_ url: URL, _ error: Error) {
  FileHandle.standardError.write(Data("\(url.path): \(error.localizedDescription)\n".utf8))
  failed = true
}

let walker = fm.enumerator(at: cache, includingPropertiesForKeys: Array(keys)) { url, error in
  warn(url, error)
  return true  // keep going past unreadable entries
}
while let url = walker?.nextObject() as? URL {
  guard url.pathExtension == "bmp",
    let v = try? url.resourceValues(forKeys: keys),
    v.isRegularFile == true,  // never follow/delete symlinks
    let mtime = v.contentModificationDate, mtime < cutoff
  else { continue }
  do {
    try fm.removeItem(at: url)
    count += 1
    bytes += v.fileSize ?? 0
  } catch {
    warn(url, error)
  }
}
print("pruned \(count) renders, \(ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file))")
exit(failed ? 1 : 0)
