// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./Token.sol";

contract NFSwap {
    string public name = "NoFillSwap Instance Exchange"; //state variable - this value is stored on the blockchain
    Token public token;
    uint public rate = 100;

    event TokensPurchased(
        address account,
        address token,
        uint amount,
        uint rate
    );

    event TokensSold(
        address account,
        address token,
        uint amount,
        uint rate
    );

    constructor(Token _token) public {
        token = _token; //local function variable. Temporarily stored in stack memory, not heap
    }


    //implicit params - sender, value
    function buyTokens() public payable {
        // Redemption rate = # of tokens recieved for 1 ether
        // tokenAmount = Amount of Ethereum * Redemption rate
        // msg is a reserved keyword inside solidity. Not sure if it is accessed globally or accessed via callback
        uint tokenAmount =  msg.value * rate;

        //guard statement to prevent sender to purchase more tokens than is available in the account
        require(token.balanceOf(address(this)) >= tokenAmount);

        //token.transfer(msg.sender, tokenAmount);
        token.transfer(msg.sender, tokenAmount);

        // Emit an event once tokens were purchased
        emit TokensPurchased(msg.sender, address(token), tokenAmount, rate);
    }

    // implicit params - sender
    function sellTokens(uint _amount) public  {

        require(token.balanceOf(msg.sender) >= _amount);

        uint etherAmount = _amount / rate;

        // guard statement to ensure that 'this' (ie. nfSwap) has enough Ether to make the exchange
        require(address(this).balance >= etherAmount);

        token.transferFrom(msg.sender, address(this), _amount ); //transfers tokens from the entity calling this function to NFSwap
        msg.sender.transfer(etherAmount); //build in transfer method for ethereum. Transfers ETH to the entity calling this function

        emit TokensSold(msg.sender, address(token), _amount, rate);
    }
}
