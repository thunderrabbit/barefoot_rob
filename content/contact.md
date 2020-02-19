---
title: "Contact"
tags: [ "barefoot rob", "contact" ]
date: 2020-02-10T15:38:44+09:00
---

<form name="contact" method="POST" netlify-honeypot="age" data-netlify="true">
<label class="description" for="name">Name </label>
<input id="name" size="50" name="name" type="text" maxlength="255" value="" />

<p class="hidden">
  <label>Don’t fill this out if you're human: <input name="age" /></label>
</p>

<label class="description" for="email">Email </label>
<input id="email" size="50" name="email" type="text" maxlength="255" value="" />


<label class="description" for="inquiry">Inquiry </label>
<textarea id="inquiry" rows="10" cols="120" name="inquiry"></textarea>


<div>
<label class="description" for="informed">Receive updates?</label><br/>
<input id="informed_email" name="informed_email" type="checkbox" value="email" />
<label for="informed_email">Via email</label><br/>
<input id="informed_line" name="informed_line" type="checkbox" value="line" />
<label for="informed_line">Via LINE</label><br/>
<input id="informed_facebook" name="informed_facebook" type="checkbox" value="facebook" />
<label for="informed_facebook">Via Facebook</label><br/>
<input id="informed_meetup" name="informed_meetup" type="checkbox" value="meetup" />
<label for="informed_meetup">Via Meetup</label><br/>
</div>

<input id="saveForm" class="button_text" type="submit" name="submit" value="Submit" />

</form>
