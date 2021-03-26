{
	"translatorID": "2b0a6048-39c4-4f48-9e61-7a4482f87793",
	"label": "FASS",
	"creator": "Johan Quester",
	"target": "^https?://([^/]*\\.)?fass\\.se.*docType=6",
	"minVersion": "3.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2021-02-15 08:40:47"
}

function detectWeb(doc, url)	{
	if(url.indexOf('docType=6')){
		return 'journalArticle';
	}
}

function doWeb(doc, url) {

	var item = new Zotero.Item("journalArticle");
	
	var handelsnamn = ZU.xpathText(doc,'//*[@id="product-card"]/header/div/h1/text()');
	var generika = ZU.xpathText(doc, '//*[@id="product-card"]/div[3]/ul/li/a/span');
	var uppdaterat = ZU.xpathText(doc, '//*[@id="readspeaker-article-content"]/div[1]/h2[10]/following::text()[1]');
	
	var handelsnamntext = Zotero.Utilities.trimInternal(handelsnamn);	
	var generikatext = Zotero.Utilities.trimInternal(generika);
	item.title = handelsnamntext + " (" + generikatext.toLowerCase() + ")";
	item.date = Zotero.Utilities.trimInternal(uppdaterat.match('^[^ ]*')[0]);
	item.url = "http://www.fass.se";
	item.publicationTitle = "SPC, Läkemedelsverket";
	
	var linkurl = doc.location.href;
	item.attachments = [{
		url: linkurl,
		title: "FASS - " + handelsnamntext + " (" + generikatext.toLowerCase() + ")",
		mimeType: "text/html",
		snapshot: false
	}];
	item.complete();
}
