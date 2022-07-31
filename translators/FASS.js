{
	"translatorID": "2b0a6048-39c4-4f48-9e61-7a4482f87793",
	"label": "FASS",
	"creator": "Johan Quester",
	"target": "^https?://([^/]*\\.)?fass\\.se.*product",
	"minVersion": "3.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2022-08-01 10:10:47"
}

function detectWeb(doc, url) {
	var test = ZU.xpathText(doc, '//*[@id="list-of-contents"]/article/header/div[1]/h2')
	if (url.includes('docType=[3,6]+') || test == "Fass-text"){
		return 'journalArticle';
	}
}

function doWeb(doc, url) {

	var item = new Zotero.Item("webpage");
	
	// extract data from webpage
	var handelsnamn = ZU.xpathText(doc,'//*[@id="product-card"]/header/div/h1/text()');
	var generika = ZU.xpathText(doc, '//*[@id="product-card"]/div[3]/ul/li/a/span');
	var bolag = ZU.xpathText(doc, '//*[@id="companyname"]/span');
	Zotero.debug(bolag);

	// If information on revision date is available use this information as date
	if (url.includes('docType=6')) {
		var uppdaterat = ZU.xpathText(doc, '//*[@id="revision-date"]/following::p[1]/text()[1]');
		uppdaterat = Zotero.Utilities.trimInternal(uppdaterat.match('^[^\S]*')[0]);
	} else {
		var uppdaterat = ZU.xpathText(doc, '//*[@id="before-content"]')
		uppdaterat = Zotero.Utilities.trimInternal(uppdaterat.match('[\\d\/-]{4,}')[0]);
		//Zotero.debug(ZU.xpathText(doc, '//*[@id="before-content"]'))
	} 

	// format extracted inofrmation
	var handelsnamn_trimmed = Zotero.Utilities.trimInternal(handelsnamn);	
	var generika_trimmed = Zotero.Utilities.trimInternal(generika);

	// push information to item
	item.creators.push({
		"lastName": bolag,
		"creatorType": "author"
	});
	item.title = handelsnamn_trimmed + " (" + generika_trimmed.toLowerCase() + "), Produktresumé (SPC)";
	item.date = Zotero.Utilities.trimInternal(uppdaterat.match('^[^\S]*')[0]);
	item.url = "http://www.fass.se";
	item.publisher = "Läkemedelsverket";
	item.place = "Uppsala"

	//Zotero.debug(uppdaterat.match('^[^\S]*')[0])	
	
	// Create link in Zotero to the SPC in FASS
	var linkurl = doc.location.href;
	item.attachments = [{
		url: linkurl,
		title: "FASS - " + handelsnamn_trimmed + " (" + generika_trimmed.toLowerCase() + ")",
		mimeType: "text/html",
		snapshot: false
	}];

	item.complete();
	
}
