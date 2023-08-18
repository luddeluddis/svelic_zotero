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
	"lastUpdated": "2023-08-18 10:18:43"
}

function detectWeb(doc, url)	{
	if (ZU.xpathText(doc, '//*[@id="topicTitle"]')){
		return 'bookSection';
	} else if (url.includes('drug-interactions')){
		// if visiting interaction database
		return 'journalArticle';
	}
}

function doWeb(doc, url) {

	// if interaction page loaded, create interaction reference
	if (detectWeb(doc, url) == "journalArticle") {
		
		var item = new Zotero.Item("webpage");
		item.title = "Lexicomp® Drug Interactions";
		item.place  = "Waltham, MA, USA";
		item.publisher = "UpToDate, Inc."
		item.url = "https://www.uptodate.com/drug-interactions";
		item.date = "";
	} 

	//
	if  (detectWeb(doc, url) == "bookSection"){
		// create new reference (item)
		var item = new Zotero.Item("bookSection");
		// get full string of all contributers
		var contrib = ZU.xpathText(doc,'//*[@id="topicContributors"]');
		// get name of section editor to identify when author list has ended
		var sect_edit = contrib.match('Section Editors?:[^,]*')[0].match(':.*')[0].substring(1);
		// convert section-editor to regexp item
		var sect_edit_test = new RegExp(sect_edit)
		// find all authors while looping through each contributer and stop when we reach the section editor
		let authors = new Array();
		for (i = 1; i <= 5; i++){
			reg_str = ('//*[@id="topicContributors"]/dd[').concat(i,']/a')
			var suggest = ZU.xpathText(doc,reg_str).match('[^,]*')[0];
			if (sect_edit_test.test(suggest)) { 
				break; 
			}
			authors[i-1] = suggest;
		}
		// get name of editor (out of laziness we ignore any case of >1 editors)
		var deputy_editor = contrib.match('Deputy Editors?:[^,]*')[0].match(':.*')[0].substring(1);
		// get title 
		var title = ZU.xpathText(doc,'//*[@id="topicTitle"]');
		// get date of last update
		var updated = ZU.xpathText(doc, '//div[@class="litReviewSingleLine"]/span[contains(text(), "This topic last updated:")]/following-sibling::text()[1]');
		//Zotero.debug(updated);
		
		// populate the reference (the item)
		for (i = 0; i < authors.length; i++){
			item.creators.push(Zotero.Utilities.cleanAuthor(authors[i],"author"))
		}
		item.creators.push(Zotero.Utilities.cleanAuthor(deputy_editor,"editor"))
		item.title = title;
		item.date = updated;
		item.url = "https://www.uptodate.com";
		item.publicationTitle = "UpToDate";
		item.place = "UpToDate, Waltham, MA"

		// create link to the specific website through a url-snapshot
		var linkurl = doc.location.href;
		item.attachments = [{
			url: linkurl,
			title: "UpToDate - " + title,
			mimeType: "text/html",
			snapshot: false
		}];
	}
	item.complete()
}

// Analysis of XPaths of contributer section for following uptodate article (2021-02-12):

// https://www.uptodate.com/contents/mechanisms-of-atrial-fibrillation?source=mostViewed_widget

//*[@id="topicContributors"]':
//Authors:Brian Olshansky, MDRishi Arora, MD Section Editors:Bradley P Knight, MD, FACCHugh Calkins, MD Deputy Editor:Gordon M Saperia, MD

//*[@id="topicContributors"]/dt[1]/text() -> Authors: 
//*[@id="topicContributors"]/dd[1]/a -> Brian Olshansky, MD
//*[@id="topicContributors"]/dd[2]/a -> Rishi Arora, MD
//*[@id="topicContributors"]/dt[2]/text() -> Section Editors:
//*[@id="topicContributors"]/dd[3]/a -> Bradley P Knight, MD, FACC
//*[@id="topicContributors"]/dd[4]/a -> Hugh Calkins, MD
//*[@id="topicContributors"]/dt[3]/text() -> Deputy Editor:
//*[@id="topicContributors"]/dd[5]/a -> Gordon M Saperia, MD
