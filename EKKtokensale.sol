pragma solidity ^0.4.20;

import "./EKK.sol";
import "./SafeMath.sol";
import "./RefundVault.sol";
import "./Ownable.sol";

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFromPublicAllocation(address _to, uint256 _value) public returns (bool success);
    function getPublicAllocation() public view returns (uint256 value);

}

/**
* @title EKK tokensale main contract
*/
contract EKKcrowdsale is Ownable{

    using SafeMath for uint256;

    // start time is the deploy time
    uint256 public startTime = now;
    //fixed for sale
    uint public icoPeriod = 14 days; 

    // softcap
    uint256 softcap = 2000 ether;

    // address where funds are collected
    address public wallet;

    //minimum investment
    uint256 minimumInvestment = 100 finney;

    // how many token units a buyer gets per wei
    uint public price = 10000;

    // amount of raised money in wei
    uint256 public weiRaised;
    uint256 public tokenSold = 0;
    bool public isFinalized = false;
    bool isSoftcapreached = false;

    //address public creator; //Address of the contract deployer
    EKK public token;
    RefundVault public vault;

    event TokenPurchase(address indexed purchaser, uint256 amount);
    event Finalized();
    /**
    * @notice EKKcrowdsale constructor
    * @param _tokenaddress is the token totalDistributed
    */
    function EKKcrowdsale (address _tokenaddress) public {
        wallet = msg.sender;
        token = EKK(_tokenaddress);
        vault = new RefundVault(wallet);
    }
  //set ICOstarttime

  // function setStarttime (uint256 _starttime) onlyOwner public  {
  //     startTime = _starttime;
  // }

  //set ICOendtime

  // function setICOperiod (uint256 _ICOperiod) onlyOwner public  {
  //     ICOperiod = _ICOperiod;
  // }

  //set wallet address
  function setWalletAddress (address _wallet) onlyOwner public {
      wallet = _wallet;
  }

  // fallback function can be used to buy tokens
  function () external payable {
     buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {

    uint256 weiAmount = msg.value;
    uint256 tokens = getTokenAmount(weiAmount);

    require(beneficiary != address(0));
    require(validPurchase());
<<<<<<< HEAD
    require(tokens <= token.GetPublicAllocation());
    require(tokenSold <= 400000000);
=======
    require(tokens <= token.getPublicAllocation());
>>>>>>> master

    token.transferFromPublicAllocation(beneficiary, tokens);
    weiRaised = weiRaised.add(msg.value);
    tokenSold = tokenSold.add(tokens);
    emit TokenPurchase(beneficiary, tokens);

    if(weiRaised >= softcap && !isSoftcapreached) {
        isSoftcapreached = true;
        vault.close();
    }

    if(isSoftcapreached) {
        wallet.transfer(msg.value);
    } else {
        forwardFunds();
    }
  }


  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract's finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    if (!isSoftcapreached) {
      vault.enableRefunds();
    }

   // token.TransferToGrowthReserve();  //unsold tokens will be allocated back to Platrform growth reserve after destribution
    emit Finalized();
    isFinalized = true;
  }
  

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!softcapReached());
    token.refundTokens(msg.sender);
    vault.refund(msg.sender);
  }



  function softcapReached() public view returns (bool) {
    return weiRaised >= softcap;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > startTime + icoPeriod;
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {

    uint256 tokenBought = weiAmount.mul(price);
    if(weiAmount >= 200 ether) {
      if (now < startTime + 2 days ) {
        tokenBought = tokenBought.mul(120);
        tokenBought = tokenBought.div(100); //+20%
      }
      else if ( (now > startTime + 2 days) && (now < startTime + 7 days)) {
        tokenBought = tokenBought.mul(115);
        tokenBought = tokenBought.div(100); //+15%
      }
      else if ((now > startTime + 7 days) && (now < startTime + 14 days)) {
        tokenBought = tokenBought.mul(110);
        tokenBought = tokenBought.div(100); //+10%
      }
    } else {
      if (now < startTime + 2 days ) {
        tokenBought = tokenBought.mul(115);
        tokenBought = tokenBought.div(100); //+15%
      }
      else if ( (now > startTime + 2 days) && (now < startTime + 7 days)) {
        tokenBought = tokenBought.mul(110);
        tokenBought = tokenBought.div(100); //+10%
      }
      else if ((now > startTime + 7 days) && (now < startTime + 14 days)) {
        tokenBought = tokenBought.mul(105);
        tokenBought = tokenBought.div(100); //+5%
      }
    }
    return tokenBought;
  }

  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= startTime + icoPeriod;
    bool validinput = msg.value >= minimumInvestment;
    return withinPeriod && validinput;
  }


}
