//! latte-stats: how busy the machine is, for whatever shows it (the SAFE bar, the power drop).
//!
//!   latte-stats [SECONDS]     one JSON line now and then one every SECONDS (default 1), until killed
//!   latte-stats once          one line, after a short look at the processor
//!
//!   {"cpu":7,"ram":3141632000,"ram_total":16712073216,"gpu":12,"vram":412356608,"vram_total":4294967296}
//!
//! `cpu` and `gpu` are percent, the rest bytes. The three graphics fields are left out when the driver does
//! not report them (only amdgpu does, through sysfs).

use std::fs;
use std::io::Write as _;
use std::thread;
use std::time::Duration;

/// (busy, total) jiffies from the first line of /proc/stat.
fn cpu_times(stat: &str) -> Option<(u64, u64)> {
    let v: Vec<u64> = stat.lines().next()?.strip_prefix("cpu ")?.split_whitespace().filter_map(|x| x.parse().ok()).collect();
    if v.len() < 5 {
        return None;
    }
    let idle = v[3] + v[4]; // idle + iowait
    let total: u64 = v.iter().take(8).sum();
    Some((total - idle, total))
}

fn percent(before: (u64, u64), after: (u64, u64)) -> u64 {
    let total = after.1.saturating_sub(before.1);
    if total == 0 { 0 } else { (after.0.saturating_sub(before.0) * 100 + total / 2) / total }
}

/// (used, total) bytes of memory: what is not available counts as used.
fn memory(meminfo: &str) -> (u64, u64) {
    let kb = |key: &str| meminfo.lines().find_map(|l| l.strip_prefix(key)?.split_whitespace().next()?.parse::<u64>().ok()).unwrap_or(0);
    let total = kb("MemTotal:");
    ((total.saturating_sub(kb("MemAvailable:"))) * 1024, total * 1024)
}

/// The first card that says how busy it is: (percent, used bytes, total bytes).
fn gpu() -> Option<(u64, u64, u64)> {
    let mut cards: Vec<_> = fs::read_dir("/sys/class/drm").ok()?.flatten().map(|e| e.path())
        .filter(|p| p.file_name().and_then(|n| n.to_str()).is_some_and(|n| n.starts_with("card") && !n.contains('-')))
        .collect();
    cards.sort();
    cards.iter().find_map(|c| {
        let read = |f: &str| fs::read_to_string(c.join("device").join(f)).ok()?.trim().parse::<u64>().ok();
        Some((read("gpu_busy_percent")?, read("mem_info_vram_used").unwrap_or(0), read("mem_info_vram_total").unwrap_or(0)))
    })
}

fn line(cpu: u64, mem: (u64, u64), gpu: Option<(u64, u64, u64)>) -> String {
    let mut s = format!("{{\"cpu\":{cpu},\"ram\":{},\"ram_total\":{}", mem.0, mem.1);
    if let Some((busy, used, total)) = gpu {
        s.push_str(&format!(",\"gpu\":{busy},\"vram\":{used},\"vram_total\":{total}"));
    }
    s.push('}');
    s
}

fn main() {
    let arg = std::env::args().nth(1);
    let once = arg.as_deref() == Some("once");
    let every = Duration::from_secs_f64(arg.and_then(|a| a.parse::<f64>().ok()).filter(|s| *s >= 0.2).unwrap_or(1.0));
    let read_cpu = || cpu_times(&fs::read_to_string("/proc/stat").unwrap_or_default()).unwrap_or((0, 0));
    let mut before = read_cpu();
    loop {
        thread::sleep(if once { Duration::from_millis(250) } else { every });
        let now = read_cpu();
        let out = line(percent(before, now), memory(&fs::read_to_string("/proc/meminfo").unwrap_or_default()), gpu());
        before = now;
        // Whoever read this has gone: stop instead of running on unseen.
        if writeln!(std::io::stdout(), "{out}").is_err() || once {
            return;
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cpu_from_proc_stat() {
        let a = cpu_times("cpu  100 0 100 700 100 0 0 0 0 0\ncpu0 1 2 3\n").unwrap();
        assert_eq!(a, (200, 1000));
        let b = cpu_times("cpu  150 0 150 1000 200 0 0 0 0 0\n").unwrap();
        assert_eq!(percent(a, b), 20); // 100 busy of 500 passed
        assert_eq!(percent(a, a), 0);
        assert!(cpu_times("intr 5").is_none());
    }

    #[test]
    fn memory_counts_what_is_not_available() {
        assert_eq!(memory("MemTotal:  16000 kB\nMemFree: 1 kB\nMemAvailable:  12000 kB\n"), (4000 * 1024, 16000 * 1024));
    }

    #[test]
    fn a_card_that_says_nothing_is_left_out() {
        assert_eq!(line(7, (1, 2), None), r#"{"cpu":7,"ram":1,"ram_total":2}"#);
        assert_eq!(line(7, (1, 2), Some((12, 3, 4))), r#"{"cpu":7,"ram":1,"ram_total":2,"gpu":12,"vram":3,"vram_total":4}"#);
    }
}
