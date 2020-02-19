---
title: "Contact"
tags: [ "barefoot rob", "contact" ]
date: 2020-02-10T15:38:44+09:00
---

<form class="pure-form pure-form-stacked" name="contact" method="POST" netlify-honeypot="age" data-netlify="true">

<div>
    <label class="pure-form" for="name">
        Name:
        <input class="pure-form" id="name" size="50" name="name" type="text" maxlength="255" value="" />
    </label>
</div>

<p class="hidden">
    <label>Don’t fill this out if you're human:<input class="pure-form" name="age" /></label>
</p>

<div>
    <label class="pure-form" for="email">
        Email:
        <input class="pure-form" id="email" size="50" name="email" type="text" maxlength="255" value="" />
    </label>
</div>

<div>
    <label class="pure-form" for="inquiry">
        Inquiry:
        <textarea id="inquiry" rows="10" cols="120" name="inquiry"></textarea>
    </label>
</div>

<div>
    <label class="pure-form" for="informed">Receive updates?</label>
    <label for="informed_email">
        <input class="pure-form" id="informed_email" name="informed_email" type="checkbox" value="email" />
        Via email
    </label>
    <label for="informed_line">
        <input class="pure-form" id="informed_line" name="informed_line" type="checkbox" value="line" />
        Via LINE
    </label>
    <label for="informed_fb">
        <input class="pure-form" id="informed_fb" name="informed_fb" type="checkbox" value="facebook" />
        Via Facebook
    </label>
    <label for="informed_meetup">
        <input class="pure-form" id="informed_meetup" name="informed_meetup" type="checkbox" value="meetup" />
        Via Meetup
    </label>
</div>

<input class="pure-form" id="saveForm" class="button_text" type="submit" name="submit" value="Submit" />

</form>
