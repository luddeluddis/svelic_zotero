{
	"translatorID": "9a8e9820-46b5-455e-9edb-89491163fd50",
	"label": "Svelic",
	"creator": "Johan Quester",
	"target": "svelic.se\\/utredning",
	"minVersion": "2.1.9",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2022-08-01 10:15:20"
}

// 2022-07-19 Now returns all information to title item to comply with the Relis/Svelic citation style
function detectWeb(doc, url)	{
	if (url.includes("utredning")){
	return 'journalArticle';
	}
}

//Zotero item types:
//https://aurimasv.github.io/z2csl/typeMap.xml

function doWeb(doc, url) {
	// create new reference (item)
	var item = new Zotero.Item("webpage");
	// get full string of article/question info
	var info = ZU.xpathText(doc,'//*[@id="dbId"]/text()[1]');
	// get title
	var title = ZU.xpathText(doc,'//*[@id="tittel"]').replace(/\s$/,'');
	// get question date
	var date = ZU.xpathText(doc,'//*[@id="spmDato"]').match('[0-9\-]*$')[0];
	//extract the data from article info
	var year = info.match('[0-9]{4}')[0];
	var LIC = info.match('[^,]*$')[0];
	var databas = 'RELIS database';
	var idnr = info.match('id.nr. [^,]*')[0].substring(7);
	var linkurl = doc.location.href;
	//var linkurl = 'www.svelic.se'
	
	//Combine strings to achieve (almost) correct citation format according to RELIS homepage guidelines:
	// RELIS database [årtal]; [Titel]. id.nr. [tal], [LICnamn]. (www.svelic.se)
	// e.g. RELIS database 2022; Isotretinoin för patienter med jordnöts- eller sojaallergi. id.nr. 1019, LUPP. (www.svelic.se)
	var combined_info = title + '. Id.nr. ' +  idnr + ',' + LIC + '. (' + linkurl + ')' ;
	var databas_info = databas + ' ' + year

	// if question mark in title, then remove the following period that emerged when combining the strings
	var combined_info = combined_info.replace(/\?\./g, '?');

	//Zotero.debug(idnr)

	// populate the reference (the item)
	// (by putting RELIS database as author (and using vancouver style) there will be a period and not a semicolon after the year)
	item.title = combined_info;
	item.creators.push({
		"lastName": databas_info,
		"creatorType": "author"
	});
		
	// old code (populating standard zotero reference fields)
	//item.date = date;
	//item.url = doc.location.href;
	//item.publicationTitle = LIC + ', id. nr. ' + idnr;
	//item.publisher = databas;
	//item.extra = 'type: dataset'
	
	// create link to the specific website through a url-snapshot
	var linkurl = doc.location.href;
	item.attachments = [{
		url: linkurl,
		title: "SVELIC - " + title,
		mimeType: "text/html",
		snapshot: false
	}];
	
	item.complete()
}

