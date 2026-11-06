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

Install Zotero first, then download the installer for your operating system to add or update this repository's translators and citation style:

- **Windows:** [Download the `.bat` installer](https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.bat) and double-click it.
- **macOS:** [Download the `.command` installer](https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.command), make it executable, and run it as described in the [macOS instructions](installer/README.md#macos-and-linux-installers).
- **Linux:** [Download the `.sh` installer](https://raw.githubusercontent.com/luddeluddis/svelic_zotero/main/installer/install-translators-and-style.sh) and run `bash ~/Downloads/install-translators-and-style.sh`.

The installers skip unchanged files, back up replaced files, and ask whether to disable Zotero's bundled UpToDate translator (default: Yes). This repository's `UpToDate_article.js` stays enabled. After installation, select **NLM/Vancouver (unnumbered bibliography)** in Zotero or your Word document's Zotero preferences.

See the [installer instructions](installer/README.md) for setup details, custom locations, and restoring backups.

## Updates

**2026-11-06**: Translator detection and metadata handling updated, including multi-substance FASS products and UpToDate articles/drug information. BNFC references omit editor information. Micromedex archived because it is no longer used. The unnumbered bibliography style is now based on NLM/Vancouver and renamed `nlm-citation-sequence-unnumbered-bibliography.csl`.

**2023-08-18**: UpToDate translator updated (last update date not retrieved).
**2022-08-01**: FASS, SVELIC and UpToDate translators updated. New translators added: Janusmed, MedicinesComplete, Micromedex and Lexicomp. Vancouver_unnumbered_bibliography updated.
**2021-03-26**: Repository created. FASS, SVELIC and UpToDate translators added. Vancouver_unnumbered_bibliography added.
