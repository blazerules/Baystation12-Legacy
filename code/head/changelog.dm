var/changelogmysql = null

client/verb/showchanges()
	if(!changelogmysql)
		var/DBQuery/r_query = dbcon.NewQuery("SELECT * FROM `changelog` ORDER BY `id` DESC")
		changelogmysql += "<head><style type='text/css'>div.ex{width:400px;padding:10px;border-bottom:thin dashed #ff0000;margin:auto;}<body>body{font-size: 9pt;font-family: Verdana, sans-serif;}h1, h2, h3, h4, h5, h6{color: #00f;font-family: Georgia, Arial, sans-serif;}img { border: 0px; }p.lic {font-size: 6pt;}</style></head>"
		src << browse_rsc('postcardsmall.jpg')
		src << browse_rsc('somerights20.png')
		src << browse_rsc('88x31.png')
		changelogmysql += {"
<img src="postcardsmall.jpg" alt="Goon Station 13" />
<h1>Bay Station 12</h1>
<h5>Based on the Rev4407 release of the goonstation 13 code</h5>

<h4>Bay Station 12 Development Team</h4>
<p>
	<strong>Coders:</strong> Head, Aryn, Googolplexed, alfie275, Sukasa, Tagert, Biscuitry, qwertyuiopas<br>
	<strong>Spriters:</strong> Cajoes, Saint, Sukasa</strong>
</p>

<h5>GoonStation 13 Development Team</h5>
<p>
	<strong>Coders:</strong> Stuntwaffle, Showtime, Pantaloons, Nannek, Keelin, Exadv1, hobnob, Justicefries, 0staf, sniperchance, AngriestIBM, BrianOBlivion<br>
	<strong>Spriters:</strong> Supernorn, Haruhi, Stuntwaffle, Pantaloons, Rho, SynthOrange, I Said No</strong>
</p>
<br />

<p><b>Googolplexed</b> gets a special mention because he provides us with the forum and wiki server.</p>
<p></p><b>Sukasa</b> also gets a special mention for providing the game server.</p>

<br />

<p><strong>Use the forum for any complaints.</strong></p>

<br />

<h2>Changelog</h2>
		"}
		if(!r_query.Execute())
			world << "Failed-[r_query.ErrorMsg()]"
		else
			var/counter
			var/limit = 15
			while(r_query.NextRow())
				var/list/column_data = r_query.GetRowData()
				changelogmysql += "<h3>Update [column_data["id"]] - [column_data["date"]]</h3>"
				changelogmysql += "<div class='ex'>[column_data["changes"]]<br><b>By [column_data["bywho"]]</div>"
				counter++
				if(counter >= limit)
					break
		changelogmysql += "<p class=\"lic\"><a name=\"license\" href=\"http://creativecommons.org/licenses/by-nc-sa/3.0/\"><img src=\"88x31.png\" alt=\"Creative Commons License\" /></a><br><i><font size=\"1\">Except where otherwise noted, Bay Station 12 is licensed under a <a href=\"http://creativecommons.org/licenses/by-nc-sa/3.0/\">Creative Commons Attribution-Noncommercial-Share Alike 3.0 License</a>.<br>All Rights Reserved</font></i></p>"
		changelogmysql += "</body>"

		src << browse(changelogmysql,"window=changes;size=400x650;")
	else
		src << browse(changelogmysql,"window=changes;size=400x650;")