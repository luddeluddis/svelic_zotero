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
	"lastUpdated": "2025-11-28 12:11:02"
}

// Paste into the Code tab of the existing FASS translator.
// Keep the existing translator metadata (including its ID and target).
function detectWeb(doc, url) {
	if (/\/product\/\d+\/smpc(?:[/?#]|$)/.test(url)) {
		return "journalArticle";
	}
}

function doWeb(doc, url) {
	var item = new Zotero.Item("journalArticle");

	// FASS displays "Product name®, form and strength" in the page heading.
	var heading = doc.querySelector("h1");
	var headingText = heading ? ZU.trimInternal(heading.textContent) : "";
	var pageTitle = doc.title.match(/^(.+?)\s+\([^)]*\)\s*•\s*Produktresumé(?:\s|$)/);
	var handelsnamn = headingText ? headingText.split(",")[0] : (pageTitle ? pageTitle[1] : "");
	handelsnamn = ZU.trimInternal(handelsnamn.replace(/[®™]/g, ""));

	// Both desktop links and the mobile menu can be present in the same page.
	var substanceHeading = Array.from(doc.querySelectorAll("h2, h3, h4, h5, h6")).find(function (element) {
		return /^(Substans|Substanser(?: i alfabetisk ordning)?)$/.test(ZU.trimInternal(element.textContent));
	});
	var substanser = new Set();
	if (substanceHeading) {
		var links = substanceHeading.parentElement.querySelectorAll('a[href*="/substance/"]');
		for (var link of links) {
			var substans = ZU.trimInternal(link.textContent).toLowerCase();
			if (substans) {
				substanser.add(substans);
			}
		}
	}

	var namn = handelsnamn;
	if (substanser.size) {
		namn += (namn ? " " : "") + "(" + Array.from(substanser).join(",") + ")";
	}
	item.title = namn + ", Produktresumé (SPC)";

	var bolagElement = doc.querySelector(".text-button-sm");
	var bolag = bolagElement ? ZU.trimInternal(bolagElement.textContent.split(",")[0]) : "";
	if (bolag) {
		item.creators.push({
			lastName: bolag,
			creatorType: "author",
			fieldMode: 1
		});
	}

	var dateElement = doc.querySelector("#revision-date-section-content > p:nth-child(1)");
	if (dateElement) {
		item.date = ZU.trimInternal(dateElement.textContent);
	}

	item.url = "https://www.fass.se"; // The specific SPC URL is in the attachment.
	item.publisher = "Läkemedelsverket";
	item.place = "Uppsala";
	item.attachments = [{
		url: url,
		title: "FASS - " + namn,
		mimeType: "text/html",
		snapshot: false
	}];

	Zotero.debug("FASS Scraper Data -- Titel: " + item.title + " | Bolag: " + bolag + " | Datum: " + (item.date || ""));
	item.complete();
}
