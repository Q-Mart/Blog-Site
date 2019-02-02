---
layout:     post
title:      Solving Countdown
date:       2019-01-19 09:00:00
summary:    Building a program to solve the rounds of Countdown
categories: story
---

[Countdown](https://en.wikipedia.org/wiki/Countdown_(game_show)) is an
undisputed classic gameshow in the UK. And its comedy counterpart, [8 Out of 10
Cats Does
Countdown](https://en.wikipedia.org/wiki/8_Out_of_10_Cats_Does_Countdown) is
also very popular show, returning for its 17th season in 2019.

When the University of York's [Comedy Society](https://yorkcomedysoc.co.uk/)
decided to do its own comedy Countdown show, I saw this as the perfect moment
to try and build a solver for the rounds. This post documents how I solved each
round, as well as the general architecture of the final system.

The entire thing is built with Python, using Redis, Tornado and Flask. The
source code is available on Github for both the
[frontend](https://github.com/Q-Mart/riley) and
[backend](https://github.com/Q-Mart/vorderman).

### Contents
1. [Solving the Letters Round](#solving-the-letters-round)
2. [Solving the Numbers Round](#solving-the-numbers-round)
4. [An Added Extra](#an-added-extra)
5. [System Architecture](#system-architecture)
6. [Final Thoughts](#final-thoughts)
7. [FAQs](#faqs)

### Solving the Letters Round
>#### The Rules of the Round (in a nutshell)
>Given a random sequence of 9 letters, find the longest word that exists in
>the sequence. When generating the sequence, you have a choice between a vowel
>and a consonant. The frequency of the letters is distributed according to
>their distribution in the English language. You must have at least 3 vowels
>and 4 consonants. Once the 9 letter sequence is generated, you have 30
>seconds to find the largest word.

Solving this problem revolves around acquiring a large dataset of English
words, which there is luckily a [Github repo
for.](https://github.com/dwyl/english-words) I then parsed the dataset into a
dictionary, where the key is a string containing a set of letters in
alphabetical order, and the value is list of
words that can be made by using **all** the letters. For example:
```python
'eilnst' -> ['elints', 'enlist', 'inlets', 'intels', 'listen', 'silent', 'tinsel']
```

This will now be referred to as the *words dictionary*

Once the words dictionary is created, the letters round can be solved as so:
1. Take the 9 letters and sort them in alphabetical order.
2. Check to see if a key exists in the dictionary that is the same as the
sorted 9 letters.
3. If there is, return the value of this pair.
4. Otherwise, remove a letter from the 9 letter set, and check that this sorted
8 letter set appears as a key in the words dictionary.
5. If it doesn't, remove another letter from the original 9 letter set and try
another 8 letter set.

And so on and so forth...

To put it another way, we're performing a breadth first search, where the nodes
are sorted strings of letters, the goal is when the node appears as a key in
the word dictionary and the children of a node are subsets of the parent node's
letters with one letter removed.

Here is a visualisation of it running with the letters being TNETENNBA (read
the children of each node from left to right):

![Example run of the letters solver](/images/countdown_letters_example.png)

Initially, the words dictionary was implemented as an in-memory dictionary in
Python, but I decided to migrate it to Redis. There is no logical reason for
this, the words dictionary only took up a few Megabytes (around 5) so it wasn't
as if it was hogging RAM. I just wanted to get my hands dirty in something I
hadn't yet used, and Redis was something that had appealed to me for a long
time.

### Solving the Numbers Round
>#### The Rules of the Round (in a nutshell)
>You get to choose 6 numbers, from two piles of numbers. One pile contains 4
>'big' numbers (25, 50, 75, 100) and the other pile contains 20 'small' numbers
>(1-10 repeated twice). You cannot choose a number, only a pile, so will get a
>random number from that pile. Once 6 numbers are chosen, a random 3 digit
>'target' number is generated. You have 30 seconds to create the target by using
>basic mathematical operations (add, subtract, divide and multiply) on the 6
>randomly chosen numbers.

### An Added Extra

### System Architecture

### Final Thoughts

### FAQs
