//! latte-boot: picks the mode LatteOS starts in and counts the crashes of the NORMAL session.
//!
//!   probe                   prints the quick hardware and graphics test (TOML)
//!   select [--dry-run]      decides the mode and writes /run/latteos/{mode.toml,session.env}
//!   session-start           called as a session starts: counts it as a crash until `ok`; exit 3 = go SAFE
//!   ok [--after S] [--require PROC]
//!                           the session is healthy: the crash count goes back to 0
//!   reset                   crash count 0, and "SAFE next time" is dropped
//!   force-safe              the next boot is SAFE, once
//!   status                  the mode decided and the crash count
//!   compat [--toml]         the hardware compatibility report; exit 1 = limits, 2 = unsupported
//!
//! For tests without root: LATTE_RUN_DIR (/run/latteos), LATTE_STATE_DIR (/var/lib/latteos),
//! LATTE_CONF (/etc/latteos/boot.toml).

use latte_hw::{compat, q, Probe};
use std::env;
use std::fs;
use std::io::Write as _;
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;
use std::process::ExitCode;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const EXIT_GO_SAFE: u8 = 3;

struct Paths {
    run: PathBuf,
    state: PathBuf,
    conf: PathBuf,
}

impl Paths {
    fn new() -> Self {
        let p = |k: &str, d: &str| PathBuf::from(env::var(k).unwrap_or_else(|_| d.to_string()));
        Paths {
            run: p("LATTE_RUN_DIR", "/run/latteos"),
            state: p("LATTE_STATE_DIR", "/var/lib/latteos"),
            conf: p("LATTE_CONF", "/etc/latteos/boot.toml"),
        }
    }
    fn crash_count(&self) -> PathBuf { self.state.join("crash-count") }
    fn force_safe(&self) -> PathBuf { self.state.join("force-safe") }
    fn mode_toml(&self) -> PathBuf { self.run.join("mode.toml") }
}

/// /etc/latteos/boot.toml: plain `key = value`, no sections.
struct Config {
    /// NORMAL crashes in a row before SAFE takes over
    crash_limit: u32,
    /// how long a session has to live to count as healthy (`ok --after`)
    healthy_secs: u64,
}

impl Config {
    fn load(p: &Paths) -> Self {
        let mut c = Config { crash_limit: 2, healthy_secs: 60 };
        for line in fs::read_to_string(&p.conf).unwrap_or_default().lines() {
            let line = line.split('#').next().unwrap_or("").trim();
            let Some((k, v)) = line.split_once('=') else { continue };
            let v = v.trim().trim_matches('"');
            match k.trim() {
                "crash_limit" => c.crash_limit = v.parse().unwrap_or(c.crash_limit),
                "healthy_secs" => c.healthy_secs = v.parse().unwrap_or(c.healthy_secs),
                _ => {}
            }
        }
        c
    }
}

#[derive(Debug)]
struct Decision {
    mode: &'static str,      // normal | safe
    renderer: &'static str,  // hw | sw-gl | pixman
    tier: &'static str,      // full | standard | eco | minimal (latte_hw::tier_for) | software | safe
    /// a stable key for whoever shows the reason in the user's language
    reason_id: &'static str,
    reason: String,
}

fn safe(reason_id: &'static str, reason: impl Into<String>) -> Decision {
    Decision { mode: "safe", renderer: "pixman", tier: "safe", reason_id, reason: reason.into() }
}

fn decide(p: &Probe, cfg: &Config, crashes: u32, force_safe: bool) -> Decision {
    let cm = &p.cmdline;
    if cm.mode.as_deref() == Some("safe") {
        return safe("kernel-safe", "forced by the kernel parameter latte.mode=safe");
    }
    if force_safe {
        return safe("forced-once", "forced: SAFE was asked for this one boot");
    }
    let forced_normal = cm.mode.as_deref() == Some("normal");
    if !forced_normal && crashes >= cfg.crash_limit {
        return safe("crashes", format!("the NORMAL session crashed {crashes} times in a row (the limit is {})", cfg.crash_limit));
    }
    if cm.nomodeset {
        return safe("nomodeset", "nomodeset: no KMS graphics driver");
    }
    if p.gpus.is_empty() {
        return safe("no-gpu", "no graphics card was found (/sys/class/drm)");
    }
    let d = &p.egl_default;
    let sw = &p.egl_sw;
    let software = |reason_id, reason: String| Decision { mode: "normal", renderer: "sw-gl", tier: "software", reason_id, reason };
    // The tier comes from the main card, then the card's generation and the platform may lower it.
    let hw = |reason_id, reason: String| {
        let main = p.gpus.iter().find(|g| g.boot_vga).or(p.gpus.first());
        let (tier, mut why) = main.map(latte_hw::tier_for).unwrap_or(("standard", String::new()));
        let fam = main.and_then(compat::gpu_family);
        let (tier, cap) = compat::cap_tier(tier, fam.as_ref(), &p.platform);
        if !cap.is_empty() { why = format!("{why}, held to {tier} by {cap}"); }
        Decision { mode: "normal", renderer: "hw", tier, reason_id, reason: if why.is_empty() { reason } else { format!("{reason}; tier: {why}") } }
    };

    match cm.renderer.as_deref() {
        Some("pixman") => return safe("renderer-pixman", "forced by latte.renderer=pixman"),
        Some("sw-gl") if sw.gles_at_least(3, 0) => return software("renderer-sw", "forced by latte.renderer=sw-gl".into()),
        Some("hw") if d.gles_at_least(3, 0) => return hw("renderer-hw", "forced by latte.renderer=hw".into()),
        _ => {}
    }

    // The test ran out of time on a card with a real KMS driver: let the compositor try, as wlroots does.
    // If it fails the session crashes, and the crash count leads to SAFE.
    if d.timed_out && p.virt.is_none() {
        if let Some(g) = p.gpus.iter().find(|g| g.boot_vga && latte_hw::REAL_KMS.contains(&g.driver.as_str())) {
            return hw("probe-timeout", format!("the graphics test timed out ({} ms), going with the {} driver", d.millis, g.driver));
        }
    }
    if d.gles_at_least(3, 0) && !d.is_software() && p.virt.is_none() {
        return hw("hw", format!("hardware acceleration: {} (GLES {}.{})", d.renderer, d.gles.0, d.gles.1));
    }
    if sw.gles_at_least(3, 0) {
        return match &p.virt {
            Some(v) => software("vm-software", format!("virtual machine ({v}): software GL (llvmpipe)")),
            None => software("no-hw-gl", format!("no hardware GLES 3 ({}), software GL", if d.ok { d.renderer.as_str() } else { "unavailable" })),
        };
    }
    safe("no-gl", format!("OpenGL ES 3 is unavailable even in software ({})", sw.error))
}

fn session_env(d: &Decision) -> String {
    let mut s = format!(
        "# written by latte-boot select; do not edit\nLATTE_MODE={}\nLATTE_RENDERER={}\nLATTE_TIER={}\n",
        d.mode, d.renderer, d.tier
    );
    match d.renderer {
        // llvmpipe for the compositor (GBM) as well as its clients; LIBGL_ALWAYS_SOFTWARE alone does not reach GBM
        "sw-gl" => s.push_str("MESA_LOADER_DRIVER_OVERRIDE=kms_swrast\nLIBGL_ALWAYS_SOFTWARE=1\n"),
        "pixman" => s.push_str("WLR_RENDERER=pixman\nLIBGL_ALWAYS_SOFTWARE=1\n"),
        _ => {}
    }
    s
}

fn now() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0)
}

fn read_u32(path: &PathBuf) -> u32 {
    fs::read_to_string(path).ok().and_then(|s| s.trim().parse().ok()).unwrap_or(0)
}

/// Through a temporary file and a rename, so a reader never sees half of it.
fn write_atomic(path: &PathBuf, content: &str, mode: u32) -> std::io::Result<()> {
    if let Some(dir) = path.parent() {
        fs::create_dir_all(dir)?;
    }
    let tmp = path.with_extension("tmp");
    {
        let mut f = fs::File::create(&tmp)?;
        f.write_all(content.as_bytes())?;
        f.sync_all()?;
    }
    fs::set_permissions(&tmp, fs::Permissions::from_mode(mode))?;
    fs::rename(&tmp, path)
}

fn current_mode(p: &Paths) -> String {
    fs::read_to_string(p.mode_toml())
        .unwrap_or_default()
        .lines()
        .find_map(|l| l.strip_prefix("mode = ").map(|v| v.trim_matches('"').to_string()))
        .unwrap_or_else(|| "safe".into())
}

fn ppid() -> u32 {
    // /proc/self/stat is "pid (comm) state ppid …", and comm may hold spaces: read from the last ')'.
    fs::read_to_string("/proc/self/stat")
        .ok()
        .and_then(|s| s.rsplit_once(')').map(|(_, r)| r.to_string()))
        .and_then(|r| r.split_whitespace().nth(1).and_then(|v| v.parse().ok()))
        .unwrap_or(0)
}

fn process_running(name: &str) -> bool {
    fs::read_dir("/proc").map(|rd| {
        rd.filter_map(|e| e.ok())
            .any(|e| fs::read_to_string(e.path().join("comm")).map(|c| c.trim() == name).unwrap_or(false))
    }).unwrap_or(false)
}

/// A typo in GRUB should not decide the mode: it is reported and the choice stays automatic.
fn cmdline_warnings(c: &latte_hw::Cmdline) -> Vec<String> {
    let mut w = Vec::new();
    if let Some(m) = c.mode.as_deref().filter(|m| !["safe", "normal"].contains(m)) {
        w.push(format!("unknown latte.mode={m} (safe or normal), ignored"));
    }
    if let Some(r) = c.renderer.as_deref().filter(|r| !["hw", "sw-gl", "pixman"].contains(r)) {
        w.push(format!("unknown latte.renderer={r} (hw, sw-gl or pixman), ignored"));
    }
    w
}

fn cmd_select(p: &Paths, dry: bool) -> ExitCode {
    let cfg = Config::load(p);
    if latte_hw::wait_for_drm(Duration::from_secs(5)).is_none() {
        eprintln!("latte-boot: /dev/dri/card* did not show up within 5 s");
    }
    let probe = Probe::run();
    for w in cmdline_warnings(&probe.cmdline) {
        eprintln!("latte-boot: {w}");
    }
    let crashes = read_u32(&p.crash_count());
    let force = p.force_safe().exists();
    let d = decide(&probe, &cfg, crashes, force);

    let mut toml = String::from("# written by latte-boot select: the one place the login screen and the session read the mode from\n[mode]\n");
    toml.push_str(&format!("mode = {}\nrenderer = {}\ntier = {}\nreason_id = {}\nreason = {}\ndecided_at = {}\ncrash_count = {}\n\n",
        q(d.mode), q(d.renderer), q(d.tier), q(d.reason_id), q(&d.reason), now(), crashes));
    toml.push_str(&probe.to_toml());
    toml.push('\n');
    toml.push_str(&compat::to_toml(&probe.platform, &probe.gpus, &compat::check(&probe.platform, &probe.gpus, probe.virt.as_deref())));

    println!("latte-boot: {} · {} · {}: {} ({} ms)", d.mode, d.renderer, d.tier, d.reason, probe.millis);
    if dry {
        print!("{toml}");
        return ExitCode::SUCCESS;
    }
    let res = write_atomic(&p.mode_toml(), &toml, 0o644)
        .and_then(|_| write_atomic(&p.run.join("session.env"), &session_env(&d), 0o644));
    if let Err(e) = res {
        eprintln!("latte-boot: cannot write to {}: {e}", p.run.display());
        return ExitCode::FAILURE;
    }
    if force {
        let _ = fs::remove_file(p.force_safe());
    }
    ExitCode::SUCCESS
}

fn cmd_session_start(p: &Paths) -> ExitCode {
    if current_mode(p) != "normal" {
        return ExitCode::SUCCESS;
    }
    let cfg = Config::load(p);
    let prev = read_u32(&p.crash_count());
    if prev >= cfg.crash_limit {
        println!("latte-boot: NORMAL crashed {prev} times in a row, going SAFE");
        return ExitCode::from(EXIT_GO_SAFE);
    }
    if let Err(e) = write_atomic(&p.crash_count(), &format!("{}\n", prev + 1), 0o664) {
        eprintln!("latte-boot: cannot write the crash count ({e}); carrying on");
    }
    ExitCode::SUCCESS
}

fn cmd_ok(p: &Paths, args: &[String]) -> ExitCode {
    let cfg = Config::load(p);
    let mut after = 0u64;
    let mut require: Option<String> = None;
    let mut it = args.iter();
    while let Some(a) = it.next() {
        match a.as_str() {
            "--after" => after = it.next().and_then(|v| v.parse().ok()).unwrap_or(cfg.healthy_secs),
            "--require" => require = it.next().cloned(),
            _ => {}
        }
    }
    // The parent is the compositor that started this. If it dies while this waits, `ok` is adopted by another
    // process and must not clear the count on behalf of a session that crashed.
    let parent = ppid();
    thread::sleep(Duration::from_secs(after));
    if after > 0 && ppid() != parent {
        println!("latte-boot ok: the compositor (pid {parent}) is gone, the session is not healthy");
        return ExitCode::FAILURE;
    }
    if let Some(name) = &require {
        if !process_running(name) {
            println!("latte-boot ok: {name} is not running, the session is not healthy");
            return ExitCode::FAILURE;
        }
    }
    if current_mode(p) == "normal" {
        if let Err(e) = write_atomic(&p.crash_count(), "0\n", 0o664) {
            eprintln!("latte-boot ok: {e}");
            return ExitCode::FAILURE;
        }
        println!("latte-boot ok: the NORMAL session is healthy, crash count 0");
    }
    ExitCode::SUCCESS
}

fn cmd_status(p: &Paths) -> ExitCode {
    match fs::read_to_string(p.mode_toml()) {
        Ok(s) => print!("{}", s.split("[probe]").next().unwrap_or(&s)),
        Err(_) => println!("{} does not exist: latte-boot select has not run", p.mode_toml().display()),
    }
    println!("# now\ncrash_count_now = {}\nforce_safe = {}", read_u32(&p.crash_count()), p.force_safe().exists());
    ExitCode::SUCCESS
}

/// Without the EGL test, so it answers in ~5 ms.
fn cmd_compat(as_toml: bool) -> ExitCode {
    let pf = compat::Platform::read();
    let gpus = latte_hw::gpus();
    let virt = latte_hw::virtualization();
    let found = compat::check(&pf, &gpus, virt.as_deref());
    if as_toml {
        print!("{}", compat::to_toml(&pf, &gpus, &found));
    } else {
        println!("CPU:   {} · {} threads · x86-64-v{}", pf.cpu_model, pf.threads, pf.x86_level);
        println!("RAM:   {} MB, swap/zram {} MB", pf.ram_mb, pf.swap_mb);
        println!("Disk:  {} · {} GB free", if pf.root_hdd { "HDD" } else { "SSD/NVMe" }, pf.root_free_gb);
        println!("Boot:  {}{}{}", if pf.uefi { "UEFI" } else { "BIOS (legacy)" }, if pf.secure_boot { " · Secure Boot" } else { "" },
                 virt.as_deref().map(|v| format!(" · VM {v}")).unwrap_or_default());
        for g in &gpus {
            match compat::gpu_family(g) {
                Some(f) => println!("GPU:   {} [{}:{} {}] ~{} · driver {} · Vulkan {} · up to the {} tier",
                                    f.name, g.vendor, g.device, g.driver, f.year, f.driver, if f.vulkan { "yes" } else { "no" }, f.max_tier),
                None => println!("GPU:   {}:{} {} (generation unknown, the EGL test decides)", g.vendor, g.device, g.driver),
            }
        }
        let (cap, why) = compat::platform_cap(&pf);
        if !why.is_empty() { println!("Platform tier: {cap} at most ({why})"); }
        for x in &found {
            println!("[{}] {}{}", x.level.as_str(), x.text, if x.fix.is_empty() { String::new() } else { format!("\n       → {}", x.fix) });
        }
        if found.is_empty() { println!("All fine."); }
    }
    match found.iter().map(|x| x.level).max() {
        Some(compat::Level::Block) => ExitCode::from(2),
        Some(compat::Level::Warn) => ExitCode::from(1),
        _ => ExitCode::SUCCESS,
    }
}

fn main() -> ExitCode {
    let args: Vec<String> = env::args().skip(1).collect();
    let p = Paths::new();
    match args.first().map(String::as_str) {
        Some("probe") => {
            print!("{}", Probe::run().to_toml());
            ExitCode::SUCCESS
        }
        Some("select") => cmd_select(&p, args.iter().any(|a| a == "--dry-run")),
        Some("session-start") => cmd_session_start(&p),
        Some("ok") => cmd_ok(&p, &args[1..]),
        Some("reset") => {
            let _ = fs::remove_file(p.force_safe());
            match write_atomic(&p.crash_count(), "0\n", 0o664) {
                Ok(_) => { println!("latte-boot: crash count 0, the next boot tries NORMAL"); ExitCode::SUCCESS }
                Err(e) => { eprintln!("latte-boot reset: {e}"); ExitCode::FAILURE }
            }
        }
        Some("force-safe") => match write_atomic(&p.force_safe(), "1\n", 0o664) {
            Ok(_) => { println!("latte-boot: the next boot is SAFE"); ExitCode::SUCCESS }
            Err(e) => { eprintln!("latte-boot force-safe: {e}"); ExitCode::FAILURE }
        },
        Some("status") => cmd_status(&p),
        Some("compat") => cmd_compat(args.iter().any(|a| a == "--toml")),
        _ => {
            eprintln!("usage: latte-boot probe | select [--dry-run] | session-start | ok [--after S] [--require PROC] | reset | force-safe | status | compat [--toml]");
            ExitCode::from(2)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use latte_hw::{Cmdline, Egl, Gpu};

    #[test]
    fn bad_kernel_parameters_are_reported() {
        assert!(cmdline_warnings(&Cmdline::parse("latte.mode=safe latte.renderer=hw")).is_empty());
        let w = cmdline_warnings(&Cmdline::parse("latte.mode=wrong latte.renderer=vulkan"));
        assert_eq!(w.len(), 2);
        assert!(w[0].contains("latte.mode=wrong"));
    }

    fn egl(renderer: &str, gles: (u32, u32)) -> Egl {
        Egl { ok: true, renderer: renderer.into(), gles, ..Default::default() }
    }
    fn probe(virt: Option<&str>, d: Egl, sw: Egl, cmdline: &str) -> Probe {
        Probe {
            cmdline: Cmdline::parse(cmdline),
            virt: virt.map(String::from),
            gpus: vec![Gpu { card: "card0".into(), vendor: "0x15ad".into(), device: "0x0405".into(), driver: "vmwgfx".into(), boot_vga: true, connected: 1, vram_mb: 0, gfx: 0, apu: false }],
            egl_default: d,
            egl_sw: sw,
            platform: Default::default(),
            millis: 1,
        }
    }
    fn cfg() -> Config { Config { crash_limit: 2, healthy_secs: 60 } }
    fn vbox() -> Probe { probe(Some("virtualbox"), egl("SVGA3D; build: RELEASE;", (3, 0)), egl("llvmpipe (LLVM 22)", (3, 2)), "") }

    #[test]
    fn a_virtual_machine_renders_in_software() {
        let d = decide(&vbox(), &cfg(), 0, false);
        assert_eq!((d.mode, d.renderer, d.tier), ("normal", "sw-gl", "software"));
    }

    #[test]
    fn crashes_go_safe() {
        assert_eq!(decide(&vbox(), &cfg(), 2, false).mode, "safe");
        assert_eq!(decide(&vbox(), &cfg(), 1, false).mode, "normal");
    }

    #[test]
    fn forced_normal_ignores_crashes() {
        let mut p = vbox();
        p.cmdline = Cmdline::parse("latte.mode=normal");
        assert_eq!(decide(&p, &cfg(), 5, false).mode, "normal");
    }

    #[test]
    fn cmdline_and_flag_force_safe() {
        let mut p = vbox();
        p.cmdline = Cmdline::parse("latte.mode=safe");
        assert_eq!(decide(&p, &cfg(), 0, false).mode, "safe");
        assert_eq!(decide(&vbox(), &cfg(), 0, true).mode, "safe");
        let mut n = vbox();
        n.cmdline = Cmdline::parse("nomodeset");
        assert_eq!(decide(&n, &cfg(), 0, false).mode, "safe");
    }

    #[test]
    fn timeout_on_a_real_card_goes_normal() {
        let mut p = probe(None, Egl { timed_out: true, error: "eglinfo: timeout 3000 ms".into(), millis: 3000, ..Default::default() }, Egl::default(), "");
        p.gpus[0].driver = "amdgpu".into();
        let d = decide(&p, &cfg(), 0, false);
        assert_eq!((d.mode, d.renderer, d.reason_id), ("normal", "hw", "probe-timeout"));
        assert_eq!(decide(&p, &cfg(), 2, false).mode, "safe"); // crashes still win
    }

    #[test]
    fn timeout_without_a_real_card_stays_safe() {
        let p = probe(None, Egl { timed_out: true, ..Default::default() }, Egl::default(), ""); // vmwgfx
        assert_eq!(decide(&p, &cfg(), 0, false).mode, "safe");
    }

    #[test]
    fn real_hardware_uses_the_card() {
        let mut p = probe(None, egl("AMD Radeon RX 6700 XT", (3, 2)), egl("llvmpipe", (3, 2)), "");
        p.gpus[0] = Gpu { card: "card1".into(), vendor: "0x1002".into(), device: "0x73df".into(), driver: "amdgpu".into(),
                          boot_vga: true, connected: 1, vram_mb: 12272, gfx: 100301, apu: false };
        let d = decide(&p, &cfg(), 0, false);
        assert_eq!((d.renderer, d.tier), ("hw", "full"));
    }

    fn amd(gfx: u32, vram_mb: u64, apu: bool) -> Gpu {
        Gpu { card: "card1".into(), vendor: "0x1002".into(), device: "0x6987".into(), driver: "amdgpu".into(),
              boot_vga: true, connected: 1, vram_mb, gfx, apu }
    }

    #[test]
    fn tiers_by_card() {
        assert_eq!(latte_hw::tier_for(&amd(80003, 4096, false)).0, "eco");        // RX 550/640
        assert_eq!(latte_hw::tier_for(&amd(100302, 8192, false)).0, "standard");  // RX 6600
        assert_eq!(latte_hw::tier_for(&amd(110000, 24576, false)).0, "full");     // RX 7900 XTX
        assert_eq!(latte_hw::tier_for(&amd(90012, 512, true)).0, "minimal");      // Renoir APU
        let nv = |d: &str| Gpu { vendor: "0x10de".into(), device: d.into(), driver: "nvidia".into(), ..amd(0, 0, false) };
        assert_eq!(latte_hw::tier_for(&nv("0x1c03")).0, "eco");                   // GTX 1060
        assert_eq!(latte_hw::tier_for(&nv("0x2504")).0, "standard");              // RTX 3060
        assert!(latte_hw::tier_for(&amd(80003, 4096, false)).1.contains("gfx803"));
    }

    #[test]
    fn a_weak_platform_lowers_the_tier() {
        let mut p = probe(None, egl("AMD Radeon RX 6600", (3, 2)), Egl::default(), "");
        p.gpus[0] = amd(100302, 8192, false);
        p.platform = compat::Platform { ram_mb: 4096, threads: 4, x86_level: 3, ..Default::default() };
        let d = decide(&p, &cfg(), 0, false);
        assert_eq!((d.renderer, d.tier), ("hw", "eco"));
        assert!(d.reason.contains("4 GB RAM"), "{}", d.reason);
    }

    #[test]
    fn nothing_works_is_safe() {
        let p = probe(None, Egl::default(), Egl::default(), "");
        assert_eq!(decide(&p, &cfg(), 0, false).mode, "safe");
    }

    #[test]
    fn env_for_renderers() {
        let d = decide(&vbox(), &cfg(), 0, false);
        assert!(session_env(&d).contains("MESA_LOADER_DRIVER_OVERRIDE=kms_swrast"));
        assert!(session_env(&safe("x", "x")).contains("WLR_RENDERER=pixman"));
    }
}
