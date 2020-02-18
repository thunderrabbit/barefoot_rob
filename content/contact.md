---
title: "Contact"
tags: [ "barefoot rob", "contact" ]
date: 2020-02-10T15:38:44+09:00
---


<h1>Contact</h1>
<form name="contact" netlify>
<div class="form_description">
    <h2>Contact</h2>
</div>

<label class="description" for="name">Name </label>
<div>
    <input id="name" name="name" type="text" maxlength="255" value="" />
</div>

<label class="description" for="email">Email </label>
<div>
    <input id="email" name="email" type="text" maxlength="255" value="" />
</div>

<label class="description" for="inquiry">Inquiry </label>
<div>
    <textarea id="inquiry" name="inquiry"></textarea>
</div>

<label class="description" for="informed">Keep informed </label>
<span>
<input id="informed_email" name="informed_email" type="checkbox" value="email" />
<label for="informed_email">Via email</label>
<input id="informed_line" name="informed_line" type="checkbox" value="line" />
<label for="informed_line">Via LINE</label>
<input id="informed_facebook" name="informed_facebook" type="checkbox" value="facebook" />
<label for="informed_facebook">Via Facebook</label>
<input id="informed_meetup" name="informed_meetup" type="checkbox" value="meetup" />
<label for="informed_meetup">Via Meetup</label>

</span>

    <input id="saveForm" class="button_text" type="submit" name="submit" value="Submit" />

</form>
