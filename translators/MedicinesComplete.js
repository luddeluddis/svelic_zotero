{
	"translatorID": "7111b34c-127b-43aa-a7ac-fecd449041c4",
	"label": "MedicinesComplete",
	"creator": "Johan Quester",
	"target": "medicinescomplete\\.com",
	"minVersion": "5.0",
	"maxVersion": "",
	"priority": 100,
	"inRepository": true,
	"translatorType": 4,
	"browserSupport": "gcsibv",
	"lastUpdated": "2022-07-29 14:05:44"
}

function detectWeb(doc, url)	{
	// Check if any of 
	if (url.includes('#/content/')){
		return 'journalArticle';
	}
} 

function doWeb(doc, url) {

	// create standard reference for Lexicomp
	var item = new Zotero.Item("book");

	item.url = "https://www.medicinescomplete.com/";
	item.publisher = "Pharmaceutical Press";
	item.place = "London, UK";
	//item.date = "uppdateras periodiskt";

	// If page contains monograph with information on last update use this information as date
	if (ZU.xpathText(doc, '//*[@class="mono-updated"]')){
		var revisiondate = ZU.xpathText(doc, '//*[@class="mono-updated"]/text()');
		item.date = Zotero.Utilities.trimInternal(revisiondate.replace(/Last\ Updated/g, ''));
		Zotero.debug(revisiondate)
	}

	// populate title and author information for each database
	let editors = new Array()
	// Stockley’s Drug Interactions
	if (url.includes("/stockley")) {
		item.title = "Stockley’s Drug Interactions";
		editors[0] = "Claire Preston";
		Zotero.debug(editors);
	}

	// Stockley's Herbal Medicines Interactions
	else if (url.includes("/shmi/")) {
		item.title = "Stockley's Herbal Medicines Interactions";
		editors[0] = "Elizabeth Williamson";
		editors[1] = "Samuel Driver";
		editors[2] = "Karen Baxter";
		editors[3] = "Claire Preston";
	}
	// Pharmaceutical Excipients
	else if (url.includes("excipients")) {
		item.title = "Pharmaceutical Excipients";
		editors[0] = "Paul Sheskey";
		editors[1] = "Bruno Hancock";
		editors[2] = "Gary Moss";
		editors[3] = "David Goldfarb";
	}
	// Injectable Drugs Guide
	else if (url.includes("/idg/")) {
		item.title = "Injectable Drugs Guide";
		editors[0] = "Alistair Gray";
		editors[1] = "Jane Wright";
		editors[2] = "Vincent Goodey";
		editors[3] = "Lynn Bruce";
	}
	// Herbal Medicines
	else if (url.includes("/herbals/")) {
		item.title = "Herbal Medicines";
	}
	// Briggs Drugs in Pregnancy and Lactation
	else if (url.includes("/dpl/")) {
		item.title = "Briggs Drugs in Pregnancy and Lactation";
		editors[0] = "Gerald G. Briggs";
		editors[1] = "Alicia B. Forinash";
		editors[2] = "Craig V. Towers";
	}
	// British National Formulary for Children
	else if (url.includes("/bnfc/")) {
		item.title = "British National Formulary for Children";
		editors[0] = "Paediatric_Formulary_Committee";
	}

	// Handbook of Drug Administration via Enteral Feeding Tubes
	else if (url.includes("/tubes/")) {
		item.title = "British National Formulary for Children";
		editors[0] = "Vicky Bradnam";
		editors[1] = "Rebecca White";
	}

	// Populate the editors to the items
	if (editors != null) {
		Zotero.debug(typeof editors);
		for (i = 0; i < editors.length; i++){
				item.creators.push(Zotero.Utilities.cleanAuthor(editors[i],"editor"))
		}
	}

	item.complete();

}
