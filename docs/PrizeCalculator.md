# Prize Calculator

This contract stores formula how much participant can withdraw when his selected output wins.

Function to calculate win amount:

* **calculatePrizeAmount** 

At first version we use simples prize distribution formula:

::

    Your tokens (_yourTokens) * _totalTokens / _winnersPoolTotalTokens = prize

    Example for Prediction Market:

    A prediction has 2 different outcomes (Outcome 1, Outcome 2) and initial 2000 tokens prize:

    User A placed 100 tokens on Outcome 1
    User B placed 300 tokens on Outcome 1
    User C placed 100 tokens on Outcome 2
    Total contributed tokens: 2500

    After the prediction resolves, the Oracle decides the winning outcome is Outcome 1. 
    Users can now withdraw the following token amount from their forecasts:

    User A -> 100 * 2500 / (100 + 300) = 625 Tokens
    User B -> 300 * 2500 / (100 + 300) = 1875 Tokens
    User C -> 0 tokens


    Example for Pools:

    A pool collected 2000 tokens reserve:

    User A placed 1500 tokens
    User B placed 500 tokens

    After insurance product ended and return 2800 tokens as a leftover to pool.
    User can now withdraw the following token amount from their contribution:

    User A -> 1500 * 2800 / 2000 = 2100 Tokens
    User B ->  500 * 2800 / 2000 = 700 Tokens
