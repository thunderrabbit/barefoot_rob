---
title: "Bold Life Tribe - Registration"
tags: [ "bold-life-tribe", "registration" ]
categories: [ "bold-life-tribe" ]
author: Rob Nugen
date: 2021-11-07T13:23:00+09:00
aliases: [
"/en/bold-life-brotherhood/registration/",
"/en/bold-life-tribe/registration/",
"/bold-life-brotherhood/registration/",
"/bold-life-tribe/registration/",
]
---

Ready to start your Bold Life?

<form class="pure-form pure-form-stacked" name="contact" method="POST"
netlify-honeypot="sage" data-netlify="true">

<div>
    <label class="pure-form" for="name">
        Name:
        <input class="pure-form" id="name" size="50" name="name" type="text" maxlength="255" value="" />
    </label>
</div>

<p class="hidden">
    <label>Don’t fill this out if you're human:<input class="pure-form" name="sage" /></label>
</p>

<div>
    <label class="pure-form" for="email">
        Email or other contact info:
        <input class="pure-form" id="email" size="50" name="email" type="text" maxlength="255" value="" />
    </label>
</div>

<div>
    <label class="pure-form" for="inquiry">
        What do you hope to gain from joining Bold Life Tribe?
        <textarea id="inquiry" rows="10" cols="120" name="inquiry"></textarea>
    </label>
</div>

<div>
    Read and agree to the <a href="/bold-life-brotherhood/agreements/">agreements</a>?
    <label for="agree_to_agreements">
        <input class="pure-form" id="agree_to_agreements" name="agree_to_agreements" type="checkbox" value="email" />
        Yes, I have read and agree to the agreements.
    </label>
</div>

<input class="pure-form" id="saveForm" class="button_text" type="submit" name="submit" value="Submit" />

</form>
