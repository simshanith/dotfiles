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
let cache = URL.homeDirectory.appending(
  path: "Library/Containers/com.apple.wallpaper.agent/Data/Library/Caches/com.apple.wallpaper.caches")

struct PruneResult {
  var removed = 0
  var bytes: Int64 = 0
  var failures = 0
}

func eprint(_ message: String) {
  FileHandle.standardError.write(Data("\(message)\n".utf8))
}

/// Deletes regular `.bmp` files under `dir` last modified before `cutoff`.
/// Symlinks are never followed or deleted.
func pruneRenders(in dir: URL, olderThan cutoff: Date) -> PruneResult {
  var result = PruneResult()
  let keys: Set<URLResourceKey> = [.isRegularFileKey, .contentModificationDateKey, .fileSizeKey]
  let files = FileManager.default.enumerator(at: dir, includingPropertiesForKeys: Array(keys)) { url, error in
    eprint("\(url.path): \(error.localizedDescription)")
    result.failures += 1
    return true  // keep walking past unreadable entries
  }
  guard let files else { return result }

  for case let file as URL in files where file.pathExtension == "bmp" {
    guard let values = try? file.resourceValues(forKeys: keys),
      values.isRegularFile == true,
      let modified = values.contentModificationDate, modified < cutoff
    else { continue }
    do {
      try FileManager.default.removeItem(at: file)
      result.removed += 1
      result.bytes += Int64(values.fileSize ?? 0)
    } catch {
      eprint("\(file.path): \(error.localizedDescription)")
      result.failures += 1
    }
  }
  return result
}

let summary = pruneRenders(in: cache, olderThan: .now - maxAge)
print("pruned \(summary.removed) renders, \(summary.bytes.formatted(.byteCount(style: .file)))")
exit(summary.failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE)
