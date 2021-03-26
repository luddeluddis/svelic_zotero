{
	"translatorID": "9a8e9820-46b5-455e-9edb-89491163fd50",
	"label": "Svelic",
	"creator": "Johan Quester",
	"target": "https:\\/\\/svelic.se\\/utredning",
	"minVersion": "3.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2021-02-15 08:19:40"
}

function detectWeb(doc, url)	{
	if (ZU.xpathText(doc, '//*[@id="spmDato"]')){
		return 'bookSection';
	}
}

//Zotero item types:
//https://aurimasv.github.io/z2csl/typeMap.xml#map-journalArticle

function doWeb(doc, url) {
	// create new reference (item)
	var item = new Zotero.Item("bookSection");
	// get full string of article/question info
	var info = ZU.xpathText(doc,'//*[@id="dbId"]/text()[1]');
	// get title
	var title = ZU.xpathText(doc,'//*[@id="tittel"]');
	// get question date
	var date = ZU.xpathText(doc,'//*[@id="spmDato"]').match('[0-9\-]*$')[0];
	//extract the data from article info
	//var year = info.match('[0-9]{4}')[0];
	var LIC = info.match('[^,]*$')[0];
	var databas = 'RELIS databas';
	var idnr = info.match('id.nr. [^,]*')[0].substring(7);
	
	//Zotero.debug(idnr)
	// populate the reference (the item)
	item.title = title;
	item.date = date;
	item.url = doc.location.href;
	item.publicationTitle = LIC + ', id. nr. ' + idnr;
	item.publisher = databas;
	item.extra = 'type: dataset'
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
