# LIC and Zotero
This repository contains Zotero-related files developed to simplify creation and management of citations within drug information centres in Sweden. The reference examples below are illustrative; formatting depends on the selected citation style and language.

## Zotero Translators

### FASS
The translator imports reference information from the currently loaded Summary of Product Characteristics (SPC) for a drug from the Swedish drug database [FASS](https://www.fass.se/). To activate the translator for a drug, the page/button "Produktresumé" must be loaded/clicked. The translator fetches the product name, active substance(s), marketing-authorisation holder and date when the SPC was last updated. Combination products include all listed substances, and a link to the specific SPC is saved as an attachment.

When using Vancouver the reference may appear as follows (using the SPC for Wakix and Swedish language in Zotero):

>Zambon Sweden. Wakix (pitolisant), Produktresumé (SPC). 24 februari 2023 [citerad 28 november 2025]; Tillgänglig vid: https://www.fass.se

### Janusmed
The translator will save a reference from the Swedish drug information tool [Janusmed](https://janusmed.se/). If a specific tool (e.g. "Janusmed interaktioner") is loaded, this information will also be included in the reference. This translator will not fetch any information from the webpage, only deduce which tool is loaded.

When using the Vancouver style the reference may appear as follows (using "Janusmed interaktioner" as an example):
>Janusmed interaktioner [Internet]. Stockholm: Hälso- och sjukvårdsförvaltningen, Region Stockholm; [citerad 29 juli 2022]. Tillgänglig vid: https://janusmed.se


### MedicinesComplete
The translator will save a reference for a selection of databases/publications available (as a subscription) via [MedicinesComplete](https://www.new.medicinescomplete.com/). The translator detects the publication from the URL and returns a prespecified reference. The following databases/publications are supported: Stockley's Drug Interactions, Stockley's Herbal Medicines Interactions, Pharmaceutical Excipients, Injectable Drugs Guide, Herbal Medicines, Briggs Drugs in Pregnancy and Lactation, British National Formulary for Children.

When using the Vancouver style the reference can appear as follows (using Stockley's Drug Interactions as an example):
>Preston C, redaktör. Stockley’s Drug Interactions [Internet]. London, UK: Pharmaceutical Press; [citerad 29 juli 2022]. Tillgänglig vid: https://www.medicinescomplete.com/

BNFC references use URL recognition only: the publication title is saved without editor information, a substance name or an update date. The feeding-tube handbook title and unrecognised publication URLs still need correction.

### Lexicomp
The translator will save a reference for the drug information service [Lexicomp](https://online.lexi.com/). If a specific database is queried for a specific drug (i.e. a drug name is shown next to the database name in the title/header of the webpage) this information is added to the reference. If this information is not available (e.g. for the databases "Drug interactions", "Trissel's IV Compatibility") a more generic reference will be created. If information about the time of the last monograph update is available/loaded, this information will also be included in the reference.

When using the Vancouver style the reference may appear as follows (using Lexi-Drugs Multinational as an example):
>Lexicomp® Online. Domperidone [Internet]. Lexi-Drugs Multinational. Waltham, MA, USA: UpToDate, Inc.; 2022 [citerad 29 juli 2022]. Tillgänglig vid: https://online.lexi.com


### SVELIC
The SVELIC translator will save a reference for the loaded investigation from the Swedish drug information website [SVELIC](https://svelic.se/) (a frontend for the Norwegian/Swedish database RELIS). Using the Vancouver style, the translator will format the reference to comply with the RELIS reference formatting to enable internal linking when publishing the reference list on SVELIC or [RELIS](https://relis.no/).

When using the Vancouver style the reference may appear as follows:
>RELIS database 2022. Finns det risker för fortsatt hemolys vid användning av olika 5-ASA-preparat? Id.nr. 1017, LUPP. (https://svelic.se/utredning/?id=11-1017).


### UpToDate_article
The translator saves the loaded [UpToDate](https://www.uptodate.com/) clinical article or drug-information monograph as a book section. Clinical articles use **UpToDate** as the book title; drug-information pages use **UpToDate Lexidrug**. Authors, editors and the last-update date are extracted when available, and a link to the specific article is saved. The UpToDate Drug Interactions tool receives a generic reference titled **Lexicomp® Drug Interactions**. Let the page finish loading before saving; a reload may be needed if it is not recognised.

When using the Vancouver style the reference may appear as follows:

>Plon SE, Jonasch E. Molecular biology and pathogenesis of von Hippel-Lindau disease. I: Shah S, redaktör. UpToDate [Internet]. UpToDate, Waltham, MA; 2021 [citerad 29 juli 2022]. Tillgänglig vid: https://www.uptodate.com


## Archived translators

### Micromedex

Archived because we no longer use or have access to Micromedex. The translator is preserved in [archive/translators/Micromedex.js](archive/translators/Micromedex.js) for reference and is no longer maintained or tested.

## Styles

#### NLM/Vancouver (unnumbered bibliography)
This style is based on [NLM/Vancouver: Citing Medicine 2nd edition (citation-sequence)](https://www.zotero.org/styles/nlm-citation-sequence), downloaded on 2026-11-06 from the [CSL styles repository](https://github.com/citation-style-language/styles/blob/e1273bfb04965d278954ef7f55a4ef8a9c364bf2/nlm-citation-sequence.csl). It appears in Zotero as **NLM/Vancouver (unnumbered bibliography)**.

Bibliography entries have no leading numbers or number-alignment column. Apply Word's own numbered-list formatting when numbers are needed; this makes them easy to remove before transferring references to RELIS. Numeric in-text citations remain `(1)`, `(2)`, etc., and references remain in citation order.

The previous customization that displays the full publication date for webpages and other default item types is preserved. Upstream author attribution and the CC BY-SA 3.0 license are retained. The custom style has its own title and ID so updates to the standard NLM style do not overwrite it.

Install the updated CSL file and select **NLM/Vancouver (unnumbered bibliography)** in Zotero or the Word document's Zotero preferences. The file is [nlm-citation-sequence-unnumbered-bibliography.csl](styles/nlm-citation-sequence-unnumbered-bibliography.csl). The old custom style had a different internal ID, so Zotero may show both until the older entry is removed.

## Installation
### Windows installer

Download [install-translators-and-style.bat](https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.bat) (save the file, then double-click it). Both scripts live in the `installer` directory; they install translators and the citation style into an existing Zotero installation. Close Zotero first. The `.bat` launcher runs an adjacent `.ps1` file if present; otherwise it downloads and runs the [PowerShell installer](installer/install-translators-and-style.ps1) from this public repository. Windows PowerShell 5.1, an internet connection, and a writable Zotero data directory are required; administrator access is not needed. The published installer and files are served from `main`.

The installer:

- Installs the six maintained translators and **NLM/Vancouver (unnumbered bibliography)** from a single GitHub commit. Archived translators are excluded.
- Uses `%USERPROFILE%\Zotero` by default. If it cannot find `zotero.sqlite`, it asks for the actual data directory. Find it in **Zotero Settings > Advanced > Files and Folders > Show Data Directory**.
- Downloads all files before installation and compares SHA-256 hashes. Identical files are skipped; different files are replaced, including local edits. Previous versions are saved under `svelic-installer-backups` in the data directory.
- Asks **Disable Zotero bundled UpToDate References translator? [Y/n]**, with **Yes** as the default. It matches only Zotero's bundled translator ID (`70dc2609-d6fd-415a-822c-a2c04293cb5a`) and renames that file to end in `.js.disabled`. **Your `UpToDate_article.js` remains enabled.** Choosing No leaves the bundled translator in its current state; it does not re-enable a previously disabled copy.

Run the same batch file again whenever you want to check for updates. When used without an adjacent `.ps1` file, it fetches the current installer each time. If both scripts are kept locally, download the pair again to update the installer itself. Downloading is still necessary to compare content, but unchanged installed files are not rewritten. GitHub API rate limits or network failures stop the run with an error. If a download or validation fails, installation has not started; a later file-system error can leave a partially updated installation, so fix the reported problem and rerun.

After installation, open Zotero, restart the browser, and reload the article. Select **NLM/Vancouver (unnumbered bibliography)** in Zotero or in the Word document's Zotero preferences. This installs the custom style alongside Zotero's standard styles and replaces an earlier copy with the same filename. The older `Vancouver_unnumbered_bibliography` style has a different ID and is not removed or migrated automatically; existing Word documents keep their selected style until you change it.

Zotero automatically updates its bundled translators and may restore **UpToDate References**. Rerun the installer to disable it again. Renaming it does not permanently opt it out of Zotero updates. If the browser still uses old translators, check that the Connector is communicating with the running Zotero desktop application. See [Zotero's translator documentation](https://www.zotero.org/support/dev/translators) and [Connector preferences](https://www.zotero.org/support/connector/preferences/advanced).

To restore the bundled translator, close Zotero and rename `UpToDate References.js.disabled` back to `UpToDate References.js` in the `translators` directory, provided an enabled copy is not already present. A translator with an older name uses that original name plus `.disabled`. Repeated disables keep additional copies with a unique suffix. To restore replaced custom files, close Zotero and copy the desired files from `svelic-installer-backups/<run>/` into the corresponding `translators` or `styles` directory.

For a custom location or scripted use, download the PowerShell file and run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\install-translators-and-style.ps1 -DataDirectory "D:\Zotero" -DisableDefaultUpToDate Yes
```

`-DisableDefaultUpToDate` accepts `Ask` (default), `Yes`, or `No`. The default repository is `luddeluddis/svelic_zotero`, branch `main`; the PowerShell script also accepts `-Repository owner/name` and `-Ref branch-or-commit` for testing a published fork or branch. Without an adjacent `.ps1`, the batch launcher downloads the installer from the default repository's `main` branch. Execution policy bypass applies only to the launched process and does not change the machine's policy. If your organisation blocks scripts, ask IT to approve the files or use manual installation.

The isolated installer tests can be run from the repository root with `pwsh -NoProfile -File installer/tests/installer.test.ps1`. They use temporary folders and simulated downloads. They do not touch your Zotero library. The PowerShell tests have passed on Linux; a Windows batch-file smoke test remains necessary.

### Manual installation

Zotero translators should be placed in the “translators” subdirectory of the [Zotero data directory](https://www.zotero.org/support/zotero_data#locating_your_zotero_library "/support/zotero_data#locating_your_zotero_library").

For installation of styles, see the Zotero support page on [Citation Styles](https://www.zotero.org/support/styles).

## Updates

**2026-11-06**: Translator detection and metadata handling updated, including multi-substance FASS products and UpToDate articles/drug information. BNFC references omit editor information. Micromedex archived because it is no longer used. The unnumbered bibliography style is now based on NLM/Vancouver and renamed `nlm-citation-sequence-unnumbered-bibliography.csl`.

**2023-08-18**: UpToDate translator updated (last update date not retrieved).
**2022-08-01**: FASS, SVELIC and UpToDate translators updated. New translators added: Janusmed, MedicinesComplete, Micromedex and Lexicomp. Vancouver_unnumbered_bibliography updated.
**2021-03-26**: Repository created. FASS, SVELIC and UpToDate translators added. Vancouver_unnumbered_bibliography added.
