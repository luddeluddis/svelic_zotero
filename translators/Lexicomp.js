{
	"translatorID": "bf16028e-e50c-404b-9368-077c02bb4152",
	"label": "Lexicomp",
	"creator": "",
	"target": "https?://([^/]*\\\\\\\\.)?online\\.lexi\\.com",
	"minVersion": "5.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2022-07-26 14:00:31"
}

function detectWeb(doc, url)	{
	if (url.includes('action')){
		return 'journalArticle';
	}
} 

function doWeb(doc, url) {

	// create standard reference for Lexicomp
	var item = new Zotero.Item("webpage");

	item.url = "https://online.lexi.com";
	item.publisher = "UpToDate, Inc.";
	item.place = "Waltham, MA, USA";

	var creator = "Lexicomp® Online";
	item.creators.push({
		"lastName": creator,
		"creatorType": "author"
	});	

	// If page contains monograph with information on last update use this information as date
	if (ZU.xpathText(doc, '//*[@class="mono-updated"]')){
		var revisiondate = ZU.xpathText(doc, '//*[@class="mono-updated"]/text()');
		item.date = Zotero.Utilities.trimInternal(revisiondate.replace(/Last\ Updated/g, ''));
	} else {
		item.date = "";
	}

	// if a specific database is loaded where substance is shown in the title next to the database name add this information to item
	if (ZU.xpathText(doc, '//*[@class="doctitle"]')) {
		item.title  = ZU.xpathText(doc, '//*[@class="doctitle"]/text()')
		item.websiteTitle = ZU.xpathText(doc, '//*[@class="docdbname"]/text()').replace(/[\(\)]/g, '')
		//Zotero.debug(ZU.xpathText(doc, '//*[@class="doctitle"]/text()'))
	}
	// some databases are a bit more generic
	else if (url.includes("action/interact")) {
		item.title = "Lexicomp® Drug Interactions";
	}
	else if (url.includes('ivcompatibility')) {
		item.title = "Trissel's IV Compatibility";
	}
	// or if no specific database is discernible
	else {
		item.title = "Lexicomp® Online"; 
		item.creators = ""
	}
	
	item.complete();

}
/** BEGIN TEST CASES **/
var testCases = [
]
/** END TEST CASES **/
