-- PowerGoo (vypínač) ako v ploche Kvapky: polomer 19 (+4 nad ním), skoro celý v okraji (stred 3 px nad ním),
-- pri kurzore sa nadnesie najviac zo všetkých (~26 px), 66 px vľavo od TimeGoo. Klik v teste iba bublina.
return {
    id = "powergoo", nazov = "PowerGoo", ikona = "power", povaha = "pokojna", velkost = 19, rast = 0.21, vyska = 3,
    vznos = 1.8, gravitacia = 0.3, dosah = 110, zoom = true, pri = "timegoo", odstup = -66,
    klik = function(d) d:bublina("(test) ponuka Vypnúť") end,
    popis = function(d) return "koliesko: veľkosť" end,
}
