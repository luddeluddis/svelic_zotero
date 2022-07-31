{
	"translatorID": "b02d942c-24a8-4db2-8728-ef40cc4eca49",
	"label": "Janusmed",
	"creator": "Johan Quester",
	"target": "^https?://([^/]*\\\\.)?janusmed\\.se",
	"minVersion": "5.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2022-07-26 14:00:19"
}

function detectWeb(doc, url)	{
	if (url.includes('janusmed')){
		return 'journalArticle';
	}
}   

//Zotero item types:
//https://aurimasv.github.io/z2csl/typeMap.xml

function doWeb(doc, url) {

	Zotero.debug(url)

	var item = new Zotero.Item("webpage");

	item.title = "Janusmed";
	item.publisher = "Hälso- och sjukvårdsförvaltningen, Region Stockholm";
	item.place  = "Stockholm";
	item.url = "https://janusmed.se";
	item.date = "";

	if (url.includes('interaktioner')) {
		item.title = "Janusmed interaktioner";
	}

	else if (url.includes('njurfunktion')) {
		item.title = "Janusmed njurfunktion";
	}

	else if (url.includes('riskprofil')) {
		item.title = "Janusmed riskprofil";
	}

	else if (url.includes('fosterpaverkan')) {
		item.title = "Janusmed fosterpåverkan";
	}
	
	else if (url.includes('amning')) {
		item.title = "Janusmed amning";
	}

	item.complete();

}
