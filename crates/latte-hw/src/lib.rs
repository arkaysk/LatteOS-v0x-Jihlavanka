//! Hardware and graphics detection for LatteOS.
//!
//! Only the fast checks the boot needs (`latte-boot`); anything slow (Vulkan, benchmarks) belongs to a
//! program that runs after login. Standard library only, so it builds and starts with nothing else around.

pub mod compat;

use std::fmt::Write as _;
use std::fs;
use std::path::Path;
use std::process::{Command, Stdio};
use std::thread;
use std::time::{Duration, Instant};

/// The kernel command line parameters LatteOS reads.
#[derive(Debug, Default, Clone)]
pub struct Cmdline {
    /// `latte.mode=safe|normal`
    pub mode: Option<String>,
    /// `latte.renderer=hw|sw-gl|pixman`
    pub renderer: Option<String>,
    /// `nomodeset`: no KMS driver, simpledrm only
    pub nomodeset: bool,
}

impl Cmdline {
    pub fn read() -> Self {
        Self::parse(&fs::read_to_string("/proc/cmdline").unwrap_or_default())
    }

    pub fn parse(s: &str) -> Self {
        let mut c = Cmdline::default();
        for arg in s.split_whitespace() {
            match arg.split_once('=') {
                Some(("latte.mode", v)) => c.mode = Some(v.to_string()),
                Some(("latte.renderer", v)) => c.renderer = Some(v.to_string()),
                None if arg == "nomodeset" => c.nomodeset = true,
                _ => {}
            }
        }
        c
    }
}

/// KMS drivers of real cards (not simpledrm, not a virtual machine's).
pub const REAL_KMS: [&str; 6] = ["amdgpu", "radeon", "i915", "xe", "nouveau", "nvidia"];

/// A graphics card from `/sys/class/drm/cardN`.
#[derive(Debug, Clone)]
pub struct Gpu {
    pub card: String,
    /// PCI vendor id: `0x1002` AMD, `0x10de` NVIDIA, `0x8086` Intel, `0x15ad` VMware
    pub vendor: String,
    pub device: String,
    /// kernel driver: amdgpu, nvidia, i915, vmwgfx, simpledrm…
    pub driver: String,
    pub boot_vga: bool,
    /// outputs with a monitor plugged in
    pub connected: usize,
    /// 0 = unknown (only amdgpu reports it)
    pub vram_mb: u64,
    /// AMD chip generation from the kernel's KFD topology (80003 = gfx803, Polaris); 0 = unknown
    pub gfx: u32,
    /// integrated graphics
    pub apu: bool,
}

/// The KFD node of an AMD card with this PCI id: (gfx_target_version, is an APU).
fn kfd_node(pci_device: &str) -> Option<(u32, bool)> {
    let id = u32::from_str_radix(pci_device.trim_start_matches("0x"), 16).ok()?;
    for e in fs::read_dir("/sys/class/kfd/kfd/topology/nodes").ok()?.flatten() {
        let props = fs::read_to_string(e.path().join("properties")).unwrap_or_default();
        let get = |k: &str| props.lines().find_map(|l| l.strip_prefix(k)?.trim().parse::<u64>().ok()).unwrap_or(0);
        if get("device_id ") == id as u64 && get("simd_count ") > 0 {
            return Some((get("gfx_target_version ") as u32, get("cpu_cores_count ") > 0));
        }
    }
    None
}

/// The performance tier a card can carry, and why.
/// full: RDNA with 10 GB+ · standard: Vega, smaller RDNA, RTX 20+, GTX 16 · eco: GCN 1–4, GTX 10xx ·
/// minimal: integrated graphics.
pub fn tier_for(g: &Gpu) -> (&'static str, String) {
    let vram = if g.vram_mb > 0 { format!(", {} GB VRAM", (g.vram_mb + 512) / 1024) } else { String::new() };
    if g.apu {
        return ("minimal", format!("integrated graphics ({}){vram}", g.driver));
    }
    match g.vendor.as_str() {
        "0x1002" if g.gfx > 0 => {
            let (major, minor) = (g.gfx / 10000, g.gfx / 100 % 100);
            let t = match (major, minor) {
                (0..=8, _) => "eco",
                (9, _) => "standard",
                _ if g.vram_mb >= 10 * 1024 => "full",
                _ => "standard",
            };
            (t, format!("AMD gfx{major}{minor:x}{:x}{vram}", g.gfx % 100))
        }
        "0x10de" => {
            // Untested on real hardware: Turing and newer start at PCI id 0x1e00.
            let id = u32::from_str_radix(g.device.trim_start_matches("0x"), 16).unwrap_or(0);
            if id >= 0x1e00 { ("standard", format!("NVIDIA Turing or newer ({}){vram}", g.device)) }
            else { ("eco", format!("NVIDIA Maxwell/Pascal/Volta ({}){vram}", g.device)) }
        }
        "0x8086" if g.vram_mb == 0 => ("minimal", format!("Intel integrated ({})", g.driver)),
        _ => ("standard", format!("{} {}{vram}", g.vendor, g.driver)),
    }
}

pub fn gpus() -> Vec<Gpu> {
    let mut out = Vec::new();
    let Ok(rd) = fs::read_dir("/sys/class/drm") else { return out };
    let mut names: Vec<String> = rd
        .filter_map(|e| e.ok()?.file_name().into_string().ok())
        .filter(|n| n.starts_with("card") && n[4..].chars().all(|c| c.is_ascii_digit()))
        .collect();
    names.sort();
    for card in names {
        let dev = format!("/sys/class/drm/{card}/device");
        let read = |f: &str| fs::read_to_string(format!("{dev}/{f}")).unwrap_or_default().trim().to_string();
        let driver = fs::read_link(format!("{dev}/driver"))
            .ok()
            .and_then(|p| p.file_name().map(|n| n.to_string_lossy().into_owned()))
            .unwrap_or_default();
        let connected = fs::read_dir("/sys/class/drm")
            .map(|rd| {
                rd.filter_map(|e| e.ok())
                    .filter(|e| e.file_name().to_string_lossy().starts_with(&format!("{card}-")))
                    .filter(|e| fs::read_to_string(e.path().join("status")).map(|s| s.trim() == "connected").unwrap_or(false))
                    .count()
            })
            .unwrap_or(0);
        let vendor = read("vendor");
        let device = read("device");
        let vram_mb = read("mem_info_vram_total").parse::<u64>().unwrap_or(0) / 1_048_576;
        let (gfx, kfd_apu) = if vendor == "0x1002" { kfd_node(&device).unwrap_or((0, false)) } else { (0, false) };
        let apu = kfd_apu || (vendor == "0x8086" && driver == "i915" && vram_mb == 0);
        out.push(Gpu { vendor, device, boot_vga: read("boot_vga") == "1", card, driver, connected, vram_mb, gfx, apu });
    }
    out
}

/// Waits for `/dev/dri/card*`: the graphics driver may load after this starts.
/// Returns how long it took in ms, or `None` when it never came.
pub fn wait_for_drm(timeout: Duration) -> Option<u128> {
    let start = Instant::now();
    loop {
        let found = fs::read_dir("/dev/dri")
            .map(|rd| rd.filter_map(|e| e.ok()).any(|e| e.file_name().to_string_lossy().starts_with("card")))
            .unwrap_or(false);
        if found {
            return Some(start.elapsed().as_millis());
        }
        if start.elapsed() > timeout {
            return None;
        }
        thread::sleep(Duration::from_millis(50));
    }
}

/// The virtual machine this runs in (`virtualbox`, `vmware`, `qemu`…), or `None` on real hardware.
pub fn virtualization() -> Option<String> {
    let dmi = |f: &str| fs::read_to_string(format!("/sys/class/dmi/id/{f}")).unwrap_or_default().to_lowercase();
    let id = format!("{} {}", dmi("sys_vendor"), dmi("product_name"));
    for (needle, name) in [("innotek", "virtualbox"), ("virtualbox", "virtualbox"), ("vmware", "vmware"),
                           ("qemu", "qemu"), ("kvm", "kvm"), ("microsoft", "hyperv")] {
        if id.contains(needle) {
            return Some(name.to_string());
        }
    }
    let hv = fs::read_to_string("/proc/cpuinfo").map(|s| s.contains(" hypervisor")).unwrap_or(false);
    hv.then(|| "unknown".to_string())
}

/// What EGL on GBM answers: the same thing a compositor will get.
#[derive(Debug, Clone, Default)]
pub struct Egl {
    pub ok: bool,
    /// `AMD Radeon …`, `llvmpipe (LLVM 22.1.8, 256 bits)`, `SVGA3D; build: RELEASE;  LLVM;`
    pub renderer: String,
    pub gles: (u32, u32),
    pub millis: u128,
    pub error: String,
    /// The test ran out of time (a cold slow disk, a stuck driver): no proof that GL does not work.
    pub timed_out: bool,
}

impl Egl {
    pub fn is_software(&self) -> bool {
        let r = self.renderer.to_lowercase();
        r.contains("llvmpipe") || r.contains("softpipe") || r.contains("swrast")
    }
    pub fn gles_at_least(&self, major: u32, minor: u32) -> bool {
        self.ok && self.gles >= (major, minor)
    }
}

/// Runs `eglinfo -B -p gbm` (mesa-demos). The timeout keeps a stuck driver from holding up the boot.
pub fn egl_gbm(env: &[(&str, &str)], timeout: Duration) -> Egl {
    let start = Instant::now();
    let mut cmd = Command::new("eglinfo");
    cmd.args(["-B", "-p", "gbm"]).stdout(Stdio::piped()).stderr(Stdio::null());
    for (k, v) in env {
        cmd.env(k, v);
    }
    let mut child = match cmd.spawn() {
        Ok(c) => c,
        Err(e) => return Egl { error: format!("eglinfo: {e}"), ..Default::default() },
    };
    loop {
        match child.try_wait() {
            Ok(Some(_)) => break,
            Ok(None) if start.elapsed() > timeout => {
                let _ = child.kill();
                let _ = child.wait();
                return Egl { error: format!("eglinfo: timeout {} ms", timeout.as_millis()), millis: start.elapsed().as_millis(), timed_out: true, ..Default::default() };
            }
            Ok(None) => thread::sleep(Duration::from_millis(5)),
            Err(e) => return Egl { error: format!("eglinfo: {e}"), ..Default::default() },
        }
    }
    let out = child.wait_with_output().map(|o| String::from_utf8_lossy(&o.stdout).into_owned()).unwrap_or_default();
    let mut egl = parse_eglinfo(&out);
    egl.millis = start.elapsed().as_millis();
    egl
}

pub fn parse_eglinfo(out: &str) -> Egl {
    let mut egl = Egl::default();
    for line in out.lines() {
        let line = line.trim();
        if let Some(r) = line.strip_prefix("OpenGL ES profile renderer:") {
            egl.renderer = r.trim().to_string();
        } else if let Some(v) = line.strip_prefix("OpenGL ES profile version:") {
            // "OpenGL ES 3.2 Mesa 26.2.3"
            if let Some(num) = v.split_whitespace().find(|t| t.contains('.') && t.chars().next().is_some_and(|c| c.is_ascii_digit())) {
                let mut it = num.split('.').map(|p| p.parse::<u32>().unwrap_or(0));
                egl.gles = (it.next().unwrap_or(0), it.next().unwrap_or(0));
            }
        }
    }
    egl.ok = !egl.renderer.is_empty() && egl.gles.0 > 0;
    if !egl.ok {
        egl.error = "eglinfo: no OpenGL ES on GBM".into();
    }
    egl
}

/// Everything the boot checks.
#[derive(Debug, Clone)]
pub struct Probe {
    pub cmdline: Cmdline,
    pub virt: Option<String>,
    pub gpus: Vec<Gpu>,
    /// Mesa's default path: the hardware driver
    pub egl_default: Egl,
    /// forced software: `MESA_LOADER_DRIVER_OVERRIDE=kms_swrast` (llvmpipe)
    pub egl_sw: Egl,
    pub platform: compat::Platform,
    pub millis: u128,
}

impl Probe {
    pub fn run() -> Self {
        let start = Instant::now();
        let cmdline = Cmdline::read();
        let platform = compat::Platform::read();
        let gpus = gpus();
        let virt = virtualization();
        let has_drm = gpus.iter().any(|g| Path::new(&format!("/dev/dri/{}", g.card)).exists());
        // Mesa's first load from a cold slow disk takes ~12 s. With a real KMS driver a timeout means NORMAL
        // anyway, so a long wait only delays the boot; a virtual machine needs the answer and gets longer.
        let real = gpus.iter().any(|g| g.boot_vga && REAL_KMS.contains(&g.driver.as_str()));
        let t = Duration::from_millis(if real { 3_000 } else { 10_000 });
        let (egl_default, egl_sw) = if has_drm && !cmdline.nomodeset {
            // Hardware first and software only when needed: two tests at once would fight over the same disk.
            let d = egl_gbm(&[], t);
            let hw_ok = d.gles_at_least(3, 0) && !d.is_software() && virt.is_none();
            let sw = if hw_ok || d.timed_out { Egl { error: "skipped".into(), ..Default::default() } }
                     else { egl_gbm(&[("MESA_LOADER_DRIVER_OVERRIDE", "kms_swrast")], t) };
            (d, sw)
        } else {
            let e = Egl { error: "no DRM device, or nomodeset".into(), ..Default::default() };
            (e.clone(), e)
        };
        Probe { cmdline, virt, gpus, egl_default, egl_sw, platform, millis: start.elapsed().as_millis() }
    }

    /// The `[probe]` part of mode.toml.
    pub fn to_toml(&self) -> String {
        let mut s = String::new();
        let _ = writeln!(s, "[probe]");
        let _ = writeln!(s, "millis = {}", self.millis);
        let _ = writeln!(s, "virt = {}", q(self.virt.as_deref().unwrap_or("none")));
        let _ = writeln!(s, "nomodeset = {}", self.cmdline.nomodeset);
        for (name, e) in [("egl_default", &self.egl_default), ("egl_sw", &self.egl_sw)] {
            let _ = writeln!(s, "\n[probe.{name}]");
            let _ = writeln!(s, "ok = {}", e.ok);
            let _ = writeln!(s, "renderer = {}", q(&e.renderer));
            let _ = writeln!(s, "gles = \"{}.{}\"", e.gles.0, e.gles.1);
            let _ = writeln!(s, "millis = {}", e.millis);
            if !e.error.is_empty() {
                let _ = writeln!(s, "error = {}", q(&e.error));
            }
        }
        for g in &self.gpus {
            let _ = writeln!(s, "\n[[probe.gpu]]");
            let _ = writeln!(s, "card = {}", q(&g.card));
            let _ = writeln!(s, "vendor = {}", q(&g.vendor));
            let _ = writeln!(s, "device = {}", q(&g.device));
            let _ = writeln!(s, "driver = {}", q(&g.driver));
            let _ = writeln!(s, "boot_vga = {}", g.boot_vga);
            let _ = writeln!(s, "connected = {}", g.connected);
            let _ = writeln!(s, "vram_mb = {}\ngfx = {}\napu = {}", g.vram_mb, g.gfx, g.apu);
        }
        s
    }
}

/// A quoted TOML string.
pub fn q(s: &str) -> String {
    format!("\"{}\"", s.replace('\\', "\\\\").replace('"', "\\\""))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cmdline() {
        let c = Cmdline::parse("BOOT_IMAGE=/vmlinuz root=/dev/x ro latte.mode=safe nomodeset latte.renderer=pixman");
        assert_eq!(c.mode.as_deref(), Some("safe"));
        assert_eq!(c.renderer.as_deref(), Some("pixman"));
        assert!(c.nomodeset);
        assert!(!Cmdline::parse("quiet rhgb").nomodeset);
    }

    #[test]
    fn eglinfo_svga() {
        let e = parse_eglinfo("EGL version string: 1.5\nOpenGL ES profile renderer: SVGA3D; build: RELEASE;  LLVM;\nOpenGL ES profile version: OpenGL ES 3.0 Mesa 26.2.3\n");
        assert!(e.ok);
        assert_eq!(e.gles, (3, 0));
        assert!(!e.is_software());
    }

    #[test]
    fn eglinfo_llvmpipe() {
        let e = parse_eglinfo("OpenGL ES profile renderer: llvmpipe (LLVM 22.1.8, 256 bits)\nOpenGL ES profile version: OpenGL ES 3.2 Mesa 26.2.3\n");
        assert!(e.gles_at_least(3, 2));
        assert!(e.is_software());
    }

    #[test]
    fn eglinfo_empty() {
        assert!(!parse_eglinfo("").ok);
    }
}
