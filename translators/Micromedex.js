{
	"translatorID": "fd2f0836-19d8-43f5-bae2-5a16909d919c",
	"label": "Micromedex",
	"creator": "Johan Quester",
	"target": "^https?://([^/]*\\.)?micromedexsolutions\\.com\\/micromedex2\\/librarian",
	"minVersion": "5.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2022-07-26 14:00:45"
}

function detectWeb(doc, url)	{
	if (url.includes('librarian')){
		return 'journalArticle';
	}
}    

function doWeb(doc, url) {

	//Zotero item types:
	//https://aurimasv.github.io/z2csl/typeMap.xml

	// create standard reference for Micromedex
	var item = new Zotero.Item("webpage");
			
	var creator = "MICROMEDEX® Healthcare Series";
	item.creators.push({
		"lastName": creator,
		"creatorType": "author"
	});

	item.url = "http://www.micromedexsolutions.com/";
	item.publisher = "IBM Watson Health";
	item.place = "Greenwood Village, Colorado, USA";

	// If details on revisiondate is available use this information as date
	// (available if full In-Depth Answer document in Drugdex is loaded)
	if (ZU.xpathText(doc, '//*[@class="revisionDate"]')){
			var revisiondate = ZU.xpathText(doc, '//*[@class="revisionDate"]/text()');
			item.date = Zotero.Utilities.trimInternal(revisiondate.replace(/Last\ Modified\: /g, ''));
	} else {
			item.date = "";
	}

	// If Drugdex monograph is loaded add information on substance and swap CSL variables
	if (ZU.xpathText(doc, '//*[@id="landingTitle"]')) {
		item.websiteTitle = "DRUGDEX Evaluations";
		
		var substance = ZU.xpathText(doc,'//*[@id="landingTitle"]');
		item.title = substance;
	}

	// If individual database (for example Martindale) is loaded look for drugTitle and database name and use this information
	else if (ZU.xpathText(doc, '//*[@id="drugTitle"]')) {

		var database = ZU.xpathText(doc,'//*[@id="pgContentSet"]/text()');
		Zotero.debug(database.match(/[^,]+\n/g)[0]);
		item.websiteTitle = database.match(/[^,]+\n/g)[0];
		
		var substance = ZU.xpathText(doc,'//*[@id="drugTitle"][1]/text()');
		
		item.title = substance.match(/[^,]*/)[0];
	}

	// if other specific individual micromedex database is loaded add this information
	else if (url.includes('Interactions')){
		item.title = "Drug Interactions"
	}

	else if (url.includes('IVComp')){
		item.title = "IV Compatibility";
	}

	else {
		item.title = "MICROMEDEX® Healthcare Series";
		item.creators = ""
	}

	item.complete();
	
}