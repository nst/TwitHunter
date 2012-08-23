TwitHunter is an attempt to see how scoring could be useful in a Twitter client.

By scoring, I mean setting up rules that increase or descrease the score of individual tweets.

You can then filter the tweets and display only the ones with the highest score.

So far, it is just a quick hack, but it works :-)

TwitHunter also demontrates how simple it is to write a Twitter client on OS X 10.8 without using any third party library.

![TwitHunter](https://github.com/nst/TwitHunter/raw/master/art/twithunter.png "Screenshot")

A signed "nightly build" can be found at [http://seriot.ch/temp/TwitHunter.app.zip](http://seriot.ch/temp/TwitHunter.app.zip)

If the data model changes (and it will) delete <code>~/Library/Application Support/TwitHunter/TwitHunter.sqlite3</code> and relaunch.

TwitHunter is released into public domain. Do not hesitate to fork and patch.

Nicolas Seriot, 2009-04 - 2010-05 - 2012-08

---

#### Motivation

I follow more than one hundred persons on Twitter, and keeping up gets increasingly time consuming.

I could just unfollow some of them but I don't want to because sometimes I actually have enough time to read them.

Also, fun or interesting twits may be written by people posting tons of junk twits besides.

#### Scoring

I envisionned a scoring system, where you define rules that increase or decrease the score of individual tweets.

That way, when you only have 5 minutes to spend on 5 hours of tweets, you just read the tweets with the highest scores.

#### Implementation

TwitHunter is an attempt to see how scoring could be useful in a Twitter client. (Using the ugliest Twitter client on earth is not a part of the experiment.)

So far, it is just a quick hack (ca 8 hours work), but it works :-)

Basically every tweet gets 50 points. The score is then changed according to simple rules, per user or per keyword.

For instance, on the screenshot, Sebastien's tweet has 50+15 points for mentioning iPhone (keyword rule) and Fraser's one got 50+10 (user rule).

The slider is set on 53, so only tweets with 53 points or more are displayed.

Disclaimer: the data model is subject to change at anytime, so don't rely on it to store your data for now.

#### Project

I have neigher time nor interest to write a "real" Cocoa Twitter client.

Instead, I would like the scoring approach, if considered useful, to be added to full featured clients.

I would also like to try out baysian filtering when I have time.

So, don't hesitate to fork the project, it is still very young, I only added 1000 lines of my code and some Cocoa bindings, so it is still very easy to change.

By the way, my Twitter account is @nst021.
