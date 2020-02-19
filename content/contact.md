---
title: "Contact"
tags: [ "barefoot rob", "contact" ]
date: 2020-02-10T15:38:44+09:00
---

<form class="pure-form" name="contact" method="POST" netlify-honeypot="age" data-netlify="true">

<div>
    <label class="pure-form" for="name">Name </label>
    <input class="pure-form" id="name" size="50" name="name" type="text" maxlength="255" value="" />
</div>

<p class="hidden">
    <label>Don’t fill this out if you're human:<input class="pure-form" name="age" /></label>
</p>

<div>
    <label class="pure-form" for="email">Email </label>
    <input class="pure-form" id="email" size="50" name="email" type="text" maxlength="255" value="" />
</div>

<div>
    <label class="pure-form" for="inquiry">Inquiry </label>
<textarea id="inquiry" rows="10" cols="120" name="inquiry"></textarea>
</div>


<div>
    <label class="pure-form" for="informed">Receive updates?</label><br/>
    <input class="pure-form" id="informed_email" name="informed_email" type="checkbox" value="email" />
    <label for="informed_email">Via email</label><br/>
    <input class="pure-form" id="informed_line" name="informed_line" type="checkbox" value="line" />
    <label for="informed_line">Via LINE</label><br/>
    <input class="pure-form" id="informed_facebook" name="informed_facebook" type="checkbox" value="facebook" />
    <label for="informed_facebook">Via Facebook</label><br/>
    <input class="pure-form" id="informed_meetup" name="informed_meetup" type="checkbox" value="meetup" />
    <label for="informed_meetup">Via Meetup</label><br/>
</div>

<input class="pure-form" id="saveForm" class="button_text" type="submit" name="submit" value="Submit" />

</form>
