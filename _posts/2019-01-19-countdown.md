---
layout:     post
title:      Solving Countdown
date:       2019-02-03 09:00:00
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
3. [System Architecture and Brining It To The Real World](#system-architecture-and-bringing-it-to-the-real-world)
4. [Final Thoughts](#final-thoughts)
5. [FAQs](#faqs)

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

![Example run of the letters solver](/images/countdown/countdown_letters_example.png)

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

This was personally quite hard for me. I initially did some googling and came
across [this blog post](http://blog.blakehemingway.co.uk/?p=46) from Blake
Hemingway. Essentially you build a tree, where:
- The root node is the set of 6 numbers
- The transition to a child node consists of taking a pair of numbers and
  applying an arithmetic operation to it
- The child node consists of the 'new set' of numbers, that being the new
    number created by the arithmetic operation on the pair and the rest of the
    numbers

For example, a tree with the root node being (1,2) will look like this
![Example of a tree of numbers](/images/countdown/countdown_numbers_example.png)

Once the tree is generated, you simply search for a path from the root node, to
a node containing the target number, and return the sequence of transitions.

I found that the code provided on Blake's blog was incomplete and did not run
(in my experience anyway). As well as that, his solution generates a full tree,
rather than stopping generation when a node is generated that contains the
target number.

I decided to represent my tree using a custom built `class` in my code, as
opposed to a `dict` in Blake's case, but this was simply for my own
readability. As well as this, I added functionality to terminate tree
generation when the tree contains a node comprised of the target number.

Although this did work, it was way too slow; it took much longer than 30
seconds to find a solution (I never let it run to completion with a 6 number
input, as it ran for longer than 90 seconds). So, the only choice was to
regress back to using a `dict` to represent the graph. This dramatically
increased speedup; it was able to solve 5 different test cases (including the
[infamous 952 round](https://www.youtube.com/watch?v=6mCgiaAFCu8)) in under 2
seconds!

### System Architecture and Bringing It To the Real World
![System Architecture Diagram](/images/countdown/sysarch.png)

The entire thing essentially consists of two components:
1. Vorderman: The backend, responsible for actually solving both rounds. It
   consists of a Flask app, calling functions to solve the rounds.
2. Riley: The Tornado based web frontend, a (barely) usable UI.

When creating the UI, I set myself the personal challenge of using no
libraries. I was tired of feeling forced to use things like JQuery, Vue and
Angular, as well as always using Bootstrap for any websites I created. I felt
like I didn't truly understand the roots of web technology.

For that reason, the interface just uses plain old Javascript, and I took
advantage of CSS flexboxes to try and add some structure to the pages.
Although, the frontend is quite technically simple, it was a good learning
experience for someone who tries to dodge as much frontend as he can.

As well as this, I was also asked to create something that mimics the target
number generator in the numbers round for the show, this was simply written in
Javascript and added to Riley.

The end product consists of 3 docker containers:
1. Riley is enclosed in one entire container
2. The Redis Word Dictionary
3. The Flask App and round solvers of Vorderman

Dockerization meant that setting up my development environment was fairly fast
and fluid, as well as making deployment super easy. To deploy, I took a
DigitalOcean VPS, cloned the repositories, wrote the appropriate config files
and then ran all the Docker containers. **Easy**.

### Final Thoughts
When this was used in action, we found that the letters round solver was
returning some very 'odd' words. I guess this is due to the words list that I
yanked from Github, so in the future I'm definitely going to consider looking
at other words lists.

As well as that, a lot of people struggled to read the output solution for the
numbers round, which is fair. You need to understand how the solver works to
read the output. This absolutely needs to be changed to be more user friendly.

This was a tough challenge; the algorithmic thinking (specifically for the numbers
round) did not come easily to me. The time constraints, University work that I
had to do and other commitments only made this more difficult. Although there
are many flaws, I am very proud of what I produced, I think I've become a much
stronger debugger, algorithmic thinker and engineer in total.

### FAQs

#### Why did you use Tornado and Flask?
Mainly because this project was for my own learning and I wanted to have a go
at using both. Also, I originally intended to use WebSockets at one point but
scrapped the idea, Tornado's existence is a remnant of that.

#### wHY ON EARTH IS THERE NO HTTPS?
Because time. I barely managed to get this out before the show, I absolutely
should add HTTPS to this when I get the time.

#### Why the names Vorderman and Riley?
They're named after superstars from the gameshow itself! [Carol
Vorderman](https://en.wikipedia.org/wiki/Carol_Vorderman) used to have the role
of solving the number round in her head on the show, to demonstrate an answer
to contestants. She's retired now and has been replaced with [Rachel Riley](https://en.wikipedia.org/wiki/Rachel_Riley).
