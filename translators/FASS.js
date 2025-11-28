{
	"translatorID": "2b0a6048-39c4-4f48-9e61-7a4482f87793",
	"label": "FASS",
	"creator": "Johan Quester",
	"target": "^https?://(www\\.)?fass\\.se/health/product/",
	"minVersion": "3.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2025-11-28 10:49:02"
}

function detectWeb(doc, url) {
	// Regex matches: /product/, followed by digits, followed by /smpc
	if (url.match(/\/product\/\d+\/smpc/)) {
		return "journalArticle";
	}
}

function doWeb(doc, url) {
	var item = new Zotero.Item("journalArticle");

	// --- Handelsnamn ---
	// h1.break-words, take everything up to the first comma
	// We use the CSS selector h1.break-words
	var handelsnamn = "";
	var titleElement = doc.querySelector("h1.break-words");
	if (titleElement) {
		var fullTitle = titleElement.textContent;
		// Split by comma and take the first part
		if (fullTitle.includes(",")) {
			handelsnamn = fullTitle.split(",")[0];
		} else {
			handelsnamn = fullTitle;
		}
	}
	handelsnamn = ZU.trimInternal(handelsnamn);

	// --- Generika ---
	// Using CSS Selector.
	var generikaSelector = ".md\\:max-w-\\[60ch\\] > a:nth-child(1) > span:nth-child(1) > span:nth-child(1)";
	var generikaElement = doc.querySelector(generikaSelector);
	
	// Fallback to XPath if CSS fails (as Tailwind classes can be brittle)
	var generika = "";
	if (generikaElement) {
		generika = generikaElement.textContent;
	} else {
		generika = ZU.xpathText(doc, '/html/body/div[5]/div[4]/div[1]/div[2]/div[4]/div[3]/div/div/a/span/span[1]');
	}
	generika = ZU.trimInternal(generika);

	// --- Bolag ---
	// Using CSS Selector
	var bolag = "";
	var bolagElement = doc.querySelector(".text-button-sm");
	if (bolagElement) {
		bolag = bolagElement.textContent;
	}
	bolag = ZU.trimInternal(bolag);

	// --- Uppdaterat (Date) ---
	// Using CSS Selector
	var uppdaterat = "";
	var dateElement = doc.querySelector("#revision-date-section-content > p:nth-child(1)");
	if (dateElement) {
		uppdaterat = dateElement.textContent;
	}
	uppdaterat = ZU.trimInternal(uppdaterat);

	// --- Debugging ---
	Zotero.debug("FASS Scraper Data -- Namn: " + handelsnamn + " | Generika: " + generika + " | Bolag: " + bolag + " | Datum: " + uppdaterat);

	// --- Populate Item ---
	
	// Set Title: Namn (Generika), Produktresumé (SPC)
	var titleString = handelsnamn;
	if (generika) {
		titleString += " (" + generika.toLowerCase() + ")";
	}
	titleString += ", Produktresumé (SPC)";
	item.title = titleString;

	// Set Author (Company)
	if (bolag) {
		item.creators.push({
			lastName: bolag,
			creatorType: "author", 
			fieldMode: 1 // 1 indicates institutional author (single field)
		});
	}

	// Set Date
	if (uppdaterat) {
		item.date = uppdaterat;
	}

	// Static Fields
	item.url = "https://www.fass.se"; // specific link is in attachment
	item.publisher = "Läkemedelsverket";  
	item.place = "Uppsala"; 

	// Attachments
	item.attachments = [{
		url: url,
		title: "FASS - " + handelsnamn + " (" + generika.toLowerCase() + ")",
		mimeType: "text/html",
		snapshot: false
	}];

	item.complete();
}

/** BEGIN TEST CASES **/
var testCases = [
	{
		"type": "web",
		"url": "https://fass.se/health/product/20080312000022/smpc",
		"items": "multiple"
	}
]
/** END TEST CASES **/
