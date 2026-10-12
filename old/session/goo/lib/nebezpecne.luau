-- lib/nebezpecne.luau — nebezpečné príkazy chcú druhý Enter (zoznam z Text Baru klasického LatteOS, ako v Kvapkách).
-- Spoločné pre okno spúšťača LensGoo (lib/spustac.luau) a núdzové rozhranie SAFE (safe.luau). `dangerous(cmd)` → true/false.
local DANGER_WORDS = {
    sudo = true, pkexec = true, su = true, doas = true,
    rm = true, rmdir = true, shred = true, truncate = true, srm = true, unlink = true,
    dd = true, wipefs = true, fdisk = true, sfdisk = true, parted = true, blkdiscard = true,
    kill = true, killall = true, pkill = true, poweroff = true, reboot = true, shutdown = true, halt = true,
}
local DANGER = {
    "mkfs", "%-delete", "chmod%s+%-[%a]*R", "chown%s+%-[%a]*R",
    ">%s*/dev/[sn]", ">%s*/etc/", ">%s*/boot/", ">%s*/usr/",
    "%f[%w]mv%s.-%s/[%a]*%s*$",
    "dnf%s+remove", "dnf%s+erase", "dnf%s+autoremove", "rpm%s+%-e", "flatpak%s+uninstall", "flatpak%s+remove",
    "systemctl%s+stop", "systemctl%s+disable", "systemctl%s+mask", "systemctl%s+poweroff", "systemctl%s+reboot",
    "git%s+reset%s+%-%-hard", "git%s+clean%s", "git%s+push%s.-%-%-force", "git%s+push%s.-%-f%f[%W]",
    "|%s*s?h%f[%W]", "|%s*bash", "|%s*zsh", ":%(%)%s*{",
}
local function dangerous(cmd)
    for seg in string.gmatch(cmd .. ";", "(.-)[;&|`(\n]") do
        local w = string.match(seg, "^[%s$]*([%w%._/%-]+)")
        if w then
            w = string.match(w, "([^/]+)$")
            if DANGER_WORDS[w] or string.find(w, "^mkfs") then return true end
        end
    end
    for _, p in ipairs(DANGER) do if string.find(cmd, p) then return true end end
    return false
end

return dangerous
