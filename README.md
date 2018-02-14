[priq][github]
=====

Pronounced "prick". Short for (minimum) **pri**ority **q**ueue.

An Erlang implementation of a Bootstrapped Skew Binomial Min-Heap, based off of
the reference pseudocode in Chris Okasaki's Purely Functional Data Structures
book.

This implementation provides *guaranteed* (not amortized) worst case **O(1)**
for `insert`, `merge`, and `peek_min`, and **O(log(n))** `delete_min`. This is
in exchange for **O(n)** additional space requirement, compared to the number
of elements.

Issues
------

The queueing interface is still under a lot of work, and this project needs
tests, but the math and queue themselves seem to be solid.

Any discovered issues should be filed via [github][github].

Build
-----

$ rebar3 compile


Contributors
------------

Shanti Chellaram

[github]: https://github.com/shantiii/priq
