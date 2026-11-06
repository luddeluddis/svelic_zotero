# Installing translators and the citation style

Detailed instructions for the installers linked from the [project README](../README.md#installation). Zotero must already be installed.

## Windows installer

Download [install-translators-and-style.bat](https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.bat) (save the file, then double-click it). Both scripts live in the `installer` directory; they install translators and the citation style into an existing Zotero installation. If Zotero is running, the installer asks you to close it and press Enter to retry; type Q to cancel. The `.bat` launcher runs an adjacent `.ps1` file if present; otherwise it downloads and runs the [PowerShell installer](install-translators-and-style.ps1) from this public repository. Windows PowerShell 5.1, an internet connection, and a writable Zotero data directory are required; administrator access is not needed. The published installer and files are served from `main`.

The installer:

- Installs the six maintained translators and **NLM/Vancouver (unnumbered bibliography)** from a single GitHub commit. Archived translators are excluded.
- Uses `%USERPROFILE%\Zotero` by default. If it cannot find `zotero.sqlite`, it asks for the actual data directory. Find it in **Zotero Settings > Advanced > Files and Folders > Show Data Directory**.
- Downloads all files before installation and compares SHA-256 hashes. Identical files are skipped; different files are replaced, including local edits. Previous versions are saved under `svelic-installer-backups` in the data directory.
- Installs the custom UpToDate article translator with priority 50, ahead of Zotero's bundled references translator at priority 100. Both translators can remain enabled; the installer does not scan for, rename, or disable bundled translators.

Run the same batch file again whenever you want to check for updates. When used without an adjacent `.ps1` file, it fetches the current installer each time. If both scripts are kept locally, download the pair again to update the installer itself. Downloading is still necessary to compare content, but unchanged installed files are not rewritten. GitHub API rate limits or network failures stop the run with an error. If a download or validation fails, installation has not started; a later file-system error can leave a partially updated installation, so fix the reported problem and rerun.

After installation, open Zotero, restart the browser, and reload the article. Select **NLM/Vancouver (unnumbered bibliography)** in Zotero or in the Word document's Zotero preferences. This installs the custom style alongside Zotero's standard styles and replaces an earlier copy with the same filename. The older `Vancouver_unnumbered_bibliography` style has a different ID and is not removed or migrated automatically; existing Word documents keep their selected style until you change it.

Zotero can continue updating **UpToDate References** normally. The custom **UpToDate article** translator has a separate ID and a lower priority number, so it is preferred on article pages when both detect content. See [Zotero's priority documentation](https://www.zotero.org/support/dev/translators#metadata). If the browser still selects the old translator, check that the Connector is communicating with Zotero desktop, restart the browser and reload the article; you can also use **Reset Translators** in the Connector's advanced preferences to refresh its cache. See [Connector preferences](https://www.zotero.org/support/connector/preferences/advanced).

If an older installer created `UpToDate References.js.disabled`, the updated installer leaves that backup untouched. Zotero may already have restored the enabled file. If it has not, close Zotero and restore the backup to `UpToDate References.js` only if that filename is absent. The bundled translator no longer needs to be disabled. To restore replaced custom files, close Zotero and copy the desired files from `svelic-installer-backups/<run>/` into the corresponding `translators` or `styles` directory.

For a custom location or scripted use, download the PowerShell file and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-translators-and-style.ps1 -DataDirectory "D:\Zotero"
```

The default repository is `luddeluddis/svelic_zotero`, branch `main`; the PowerShell script also accepts `-Repository owner/name` and `-Ref branch-or-commit` for testing a published fork or branch. Without an adjacent `.ps1`, the batch launcher downloads the installer from the default repository's `main` branch. Execution policy bypass applies only to the launched process and does not change the machine's policy. If your organisation blocks scripts, ask IT to approve the files or use manual installation.

The isolated installer tests can be run from the repository root with `pwsh -NoProfile -File installer/tests/installer.test.ps1`. They use temporary folders and simulated downloads. They do not touch your Zotero library. The PowerShell tests have passed on Linux; a Windows batch-file smoke test remains necessary.

## macOS and Linux installers

These install the same six translators and custom citation style into an existing Zotero library. They use `~/Zotero` by default on both platforms (see [Zotero's data-directory documentation](https://www.zotero.org/support/zotero_data)). For a custom or sandboxed installation, supply the directory shown by **Zotero Settings > Advanced > Files and Folders > Show Data Directory**; the installer asks if the default directory does not contain a library.

**macOS:** Download [install-translators-and-style.command](https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.command) to Downloads. In Terminal, run:

```bash
chmod +x ~/Downloads/install-translators-and-style.command
~/Downloads/install-translators-and-style.command
```

Once executable, the `.command` file can also be double-clicked in Finder. It opens Terminal and leaves the messages visible until you press Enter. The launcher uses an adjacent `install-translators-and-style.sh` if present; otherwise it downloads the current shell installer from GitHub. If macOS or your organisation blocks a downloaded script, follow your organisation's approval process or use manual installation.

**Linux:** Download [install-translators-and-style.sh](https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.sh), then run it in a terminal:

```bash
bash ~/Downloads/install-translators-and-style.sh
```

The shared `.sh` script also runs directly on macOS. No administrator access, PowerShell, or Python is needed. Bash 3.2 or later, `curl`, `pgrep`, and standard Unix utilities are required. If a required tool is missing, the script names it. Run as your normal Zotero user; do not use `sudo`.

Both scripts ask you to close Zotero and press Enter to retry if it is running; type Q to cancel. The custom **UpToDate article** translator takes precedence by priority; the bundled translator is left enabled. Downloaded translator IDs and the style's identity/structure are checked before any installation begins; the system XML validator is also used when available. Files come from one GitHub commit, identical contents are skipped without changing file timestamps, and replaced files are backed up under `svelic-installer-backups`. Each file is replaced by a rename in its destination directory. A failure during installation can leave some files updated; correct the reported problem and rerun.

For a custom location:

```bash
bash ~/Downloads/install-translators-and-style.sh --data-directory "/path/to/Zotero"
```

Options are `--data-directory PATH`, `--repository OWNER/NAME`, and `--ref BRANCH-OR-COMMIT`. The macOS launcher forwards the same options. The restoration instructions and Zotero/Connector restart steps above apply on all platforms.

Rerun the installer to update the translators and style. A standalone macOS launcher downloads the current shell installer each time; if you keep both files together, download the pair again to update the installer itself. Linux users should download a fresh `.sh` when the installer changes.

Tests: `python3 -m unittest discover -s installer/tests -p 'test_*.py'` runs isolated tests with simulated downloads and processes. Python is only needed to run these developer tests. The shell installer and launcher logic have been tested on Linux; a native macOS Finder/Terminal smoke test remains necessary.

## Manual installation

Zotero translators should be placed in the “translators” subdirectory of the [Zotero data directory](https://www.zotero.org/support/zotero_data#locating_your_zotero_library "/support/zotero_data#locating_your_zotero_library").

For installation of styles, see the Zotero support page on [Citation Styles](https://www.zotero.org/support/styles).
