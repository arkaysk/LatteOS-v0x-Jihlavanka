-- Is this shell command one that should be confirmed before it runs?
-- It is a guard against a slip of the hand, not a sandbox: whoever wants to get past it can.
local WORDS = {
    sudo = true, pkexec = true, su = true, doas = true,
    rm = true, rmdir = true, shred = true, truncate = true, srm = true, unlink = true,
    dd = true, wipefs = true, fdisk = true, sfdisk = true, parted = true, blkdiscard = true,
    kill = true, killall = true, pkill = true, poweroff = true, reboot = true, shutdown = true, halt = true,
}
local PATTERNS = {
    "mkfs", "%-delete", "chmod%s+%-[%a]*R", "chown%s+%-[%a]*R",
    ">%s*/dev/[sn]", ">%s*/etc/", ">%s*/boot/", ">%s*/usr/",
    "%f[%w]mv%s.-%s/[%a]*%s*$",
    "dnf%s+remove", "dnf%s+erase", "dnf%s+autoremove", "rpm%s+%-e", "flatpak%s+uninstall", "flatpak%s+remove",
    "systemctl%s+stop", "systemctl%s+disable", "systemctl%s+mask", "systemctl%s+poweroff", "systemctl%s+reboot",
    "git%s+reset%s+%-%-hard", "git%s+clean%s", "git%s+push%s.-%-%-force", "git%s+push%s.-%-f%f[%W]",
    "|%s*s?h%f[%W]", "|%s*bash", "|%s*zsh", ":%(%)%s*{",
}

return function(cmd)
    -- the first word of every part of the line: `ls; rm x` is as dangerous as `rm x`
    for part in string.gmatch(cmd .. ";", "(.-)[;&|`(\n]") do
        local word = string.match(part, "^[%s$]*([%w%._/%-]+)")
        if word then
            word = string.match(word, "([^/]+)$")
            if WORDS[word] or string.find(word, "^mkfs") then return true end
        end
    end
    for _, p in ipairs(PATTERNS) do if string.find(cmd, p) then return true end end
    return false
end
