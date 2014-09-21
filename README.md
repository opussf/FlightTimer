[![Build Status](https://travis-ci.org/opussf/FlightTimer.svg?branch=master)](https://travis-ci.org/opussf/FlightTimer)


# Flight Timer

This addon shows what it expects to be the flight time for a taxi ride.
This self learns the routes that you take, and on the 2nd flight will show you the timer.

Once it knows how long a flight is, it will give a landing warning 20 seconds before you land, and alert you again once you land.
This lets you stand up, alt-tab way, or play with your real life pets while you wait to get where you are going.
First time flights will only alert you once you land.

## Configuration

Currently there is no configuration for this, just install it, and enjoy.

## Current bugs

* No completion of flight if interupted -- if you get pulled off for a dungeon, it will not continue the flight counter when you come back.
* Does not take into account guild perk of faster taxi flights.
* Does not take into account shorter flights if a newer, shorter route is used.
