# LIC and Zotero
This repository contains Zotero related files developed to simplify working with Zotero within drug information centrals in Sweden.

## Translators

### FASS
The translator imports the current loaded drug information from the Swedish drug database [FASS](https://www.fass.se/) as an item in Zotero. To activate the translator the view "Produktresumé" needs to be loaded as this exposes the date when the SPC was last updated. When using Vancouver the reference will appear as follows (using the SPC for Waran and swedish language):

>Waran (warfarin). SPC, Läkemedelsverket [Internet]. 10 november 2020 [citerad 26 mars 2021]; Tillgänglig vid: http://www.fass.se
 
### SVELIC
The translator saves a loaded investigation from the the Swedish drug information website [SVELIC](https://svelic.se/) (a frontend for the norwegian/swedish database RELIS). When using Vancouver the reference will appear as follows:

>Risker med amning vid behandling med piperacillin/tazobaktam (pip/taz)? [Internet]. LUPP, id. nr. 282. RELIS databas; 2017 [citerad 26 mars 2021]. Tillgänglig vid: https://svelic.se/utredning/?id=11-282

### UpToDate_article
Zotero comes with an UpToDate translator that enables saving references from the bibliography of [UpToDate](https://www.uptodate.com/) articles. This translator will replace the default translator (Zotero appears to be sorting translators in alphabetical order) and will save the loaded UpToDate article as an item in Zotero. Like the original translator this translator has some problem sensing an article the first time it is loaded and you often need to initially load another article. When using Vancouver the reference will appear as follows:

>Plon SE, Jonasch E. Molecular biology and pathogenesis of von Hippel-Lindau disease [Internet]. Shah S, redaktör. UpToDate. UpToDate, Waltham, MA; 2020 [citerad 26 mars 2021]. Tillgänglig vid: http://www.uptodate.com

## Styles

#### Vancouver_unnumbered_bibliography
This style is an alteration of the default CSL file Vancouver where the numbering of the bibliography has been removed. You are thus forced to use numbered lists in Microsoft Word or corresponding software to number the bibliography. As a result the numbers are easy to remove when transfering the bibliography to the RELIS database. 

## Installation
Zotero translators should be placed in the “translators” subdirectory of the [Zotero data directory](https://www.zotero.org/support/zotero_data#locating_your_zotero_library "/support/zotero_data#locating_your_zotero_library").

For installation of styles see the Zotero support page on [Citation Styles](https://www.zotero.org/support/styles).
