# Ručné inštalácie na latte-lab

Kroky, ktoré musí spustiť používateľ priamo pri latte-lab (vo VS Code, v termináli). Claude ich nespustí sám:
buď ich zastaví kontrola oprávnení Claude Code, alebo treba prihlásenie človekom. Najnovšie hore. Po dokončení
kroku ho označ `[x]` a napíš Claudovi, nech pokračuje.

## 21. 10. 2026 — DeepSeek cez webové prihlásenie (bez kľúča API)

DeepSeek v LensGoo a LensAI cez účet na chat.deepseek.com, rovnako ako Claude, Gemini či Grok cez svoje nástroje.
Oficiálny DeepSeek Harness (`dsh`, MIT) je už nainštalovaný v `~/.local/bin/dsh`. Chýba neoficiálny doplnok
[dsh-deepseek-web-login](https://github.com/cv-superding/dsh-deepseek-web-login) (Apache-2.0) a Chromium, ktorý doplnok
nevyhnutne potrebuje. **Riziko** (používateľ prijal 21. 10.): doplnok používa súkromné rozhranie webu, DeepSeek môže
účet obmedziť alebo na deň zablokovať (napríklad pri viacerých oknách naraz).

- [ ] 1. Chromium (doplnok hľadá `/usr/bin/chromium-browser`):
  ```sh
  sudo dnf install --noautoremove chromium
  ```
- [ ] 2. Doplnok do dvoch profilov dsh — `web` na prihlásenie, `headless` pre LensAI:
  ```sh
  dsh plugin --profile web add github:cv-superding/dsh-deepseek-web-login#v1.0.3
  dsh plugin --profile headless add github:cv-superding/dsh-deepseek-web-login#v1.0.3
  ```
- [ ] 3. Prihlásenie, raz: `dsh web` otvorí `http://127.0.0.1:3080`; v Nastaveniach panel „DeepSeek 网页登录“
  (DeepSeek webové prihlásenie) → prihlásenie oknom prehliadača → telefón alebo e-mail a kód. Panel potom ukáže
  „已登录“ (prihlásený). `dsh web` potom zavrieť (Ctrl+C).
- [ ] 4. Napísať Claudovi: „DeepSeek je prihlásený, zapoj ho“. Claude pridá službu `deepseek` do `latte-ai`
  (`dsh --profile headless` s `DSH_PERMISSION_MODE=read-only` a `DSH_TELEMETRY_MODE=DISABLED`, model cez `--patch`:
  `deepseek-reasoner` = čip „Hlboké myslenie“ zapnutý, `deepseek-chat` = vypnutý). Ak to kontrola oprávnení znova
  zastaví, povoliť v Claude Code (`/permissions`) Bash pre `dsh` a pre úpravy `bin/latte-ai`.
