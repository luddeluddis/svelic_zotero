{
	"translatorID": "4af8c4da-cf3d-4ec2-989f-15d4d0723bf1",
	"label": "UpToDate article",
	"creator": "Johan Quester",
	"target": "^https:?\\/\\/www\\.uptodate\\.com\\/",
	"minVersion": "3.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2026-02-06 11:31:41"
}

function detectWeb(doc, url) {
	// 1. Check for Drug Interactions tool
	if (url.includes('drug-interactions')) {
		return 'journalArticle';
	}

	// 2. Check for Standard Articles or Drug Info Pages
	if (url.includes('/contents/')) {
		return 'bookSection';
	}

	// 3. Fallback
	if (doc.title && doc.title.includes("UpToDate")) {
		return "bookSection";
	}
}

function doWeb(doc, url) {
	var type = detectWeb(doc, url);

	if (type == "journalArticle") {
		var item = new Zotero.Item("webpage");
		item.title = "Lexicomp® Drug Interactions";
		item.place = "Waltham, MA, USA";
		item.publisher = "UpToDate, Inc.";
		item.url = "https://www.uptodate.com/drug-interactions";
		item.complete();
	} 
	
	else if (type == "bookSection") {
		var item = new Zotero.Item("bookSection");

		// --- URL CLEANING ---
		// Removes "?search=..." query parameters
		item.url = url.split('?')[0];

		// --- TITLE EXTRACTION & TYPE CHECK ---
		// Get the raw title from the DOM or Title tag
		var title = ZU.xpathText(doc, '//*[@id="topicTitle"]');
		if (!title) {
			title = doc.title.replace(' - UpToDate', '').trim();
		}

		// Check if this is a "Drug information" page
		// Check doc.title because it is consistent even if the DOM ID changes
		if (doc.title.toLowerCase().includes("drug information")) {
			item.publicationTitle = "UpToDate Lexidrug";
			
			// Optional: Remove ": Drug information" from the Title so it isn't duplicated
			// Turns "Rituximab: Drug information" -> "Rituximab"
			//title = title.replace(/:? Drug information/i, "").trim();
		} else {
			item.publicationTitle = "UpToDate";
		}
		
		item.title = title;

		// --- AUTHOR EXTRACTION ---
		var contributorsDiv = doc.getElementById('topicContributors');
		if (contributorsDiv) {
			var children = contributorsDiv.children;
			var currentType = 'author'; 
			
			for (var i = 0; i < children.length; i++) {
				var child = children[i];
				
				if (child.tagName === 'DT') {
					var label = child.textContent.toLowerCase();
					if (label.includes('author')) currentType = 'author';
					else if (label.includes('section editor')) currentType = 'editor'; 
					else if (label.includes('deputy editor')) currentType = 'editor'; 
					else currentType = null; 
				}
				
				if (child.tagName === 'DD' && currentType) {
					var name = child.textContent.trim();
					// Clean credentials
					name = name.replace(/,?\s*(MD|PhD|MBBS|DO|MPH|FACC|FACP|FRCP|MBChB|PharmD).*/g, ""); 
					item.creators.push(Zotero.Utilities.cleanAuthor(name, currentType));
				}
			}
		}

		// --- DATE EXTRACTION ---
		var lastUpdated = ZU.xpathText(doc, '//div[@class="litReviewSingleLine"][contains(., "This topic last updated")]');
		if (lastUpdated) {
			item.date = lastUpdated.replace(/.*:\s*/, '').replace(/\.$/, '');
		}

		item.publisher = "UpToDate, Inc.";
		item.place = "Waltham, MA";
		
		item.attachments = [{
			url: item.url,
			title: "UpToDate - " + item.title,
			mimeType: "text/html",
			snapshot: false
		}];

		item.complete();
	}
}

/** BEGIN TEST CASES **/
var testCases = [
]
/** END TEST CASES **/
