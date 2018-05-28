pragma solidity ^0.4.20;

import "./EKK.sol";
import "./SafeMath.sol";
import "./RefundVault.sol";
import "./Ownable.sol";

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferfromThis(address _to, uint256 _value) public returns (bool success);
    function GetPublicAllocation() public view returns (uint256 value);

}

/**
* @title EKK tokensale main contract
*/
contract EKKcrowdsale is Ownable{

    using SafeMath for uint256;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint public ICOperiod = 14 days;

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
    bool public isFinalized = false;
    bool issoftcapreached = false;

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

  function setStarttime (uint256 _starttime) onlyOwner public  {
      startTime = _starttime;
  }

  //set ICOendtime

  function setICOperiod (uint256 _ICOperiod) onlyOwner public  {
      ICOperiod = _ICOperiod;
  }

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
    require(tokens <= token.GetPublicAllocation());

    token.transferfromThis(beneficiary, tokens);
    weiRaised = weiRaised.add(msg.value);
    emit TokenPurchase(beneficiary, tokens);

    if(weiRaised >= softcap && !issoftcapreached) {
        issoftcapreached = true;
        vault.close();
    }

    if(issoftcapreached) {
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

    if (!issoftcapreached) {
      vault.enableRefunds();
    }

    token.TransferToGrowthReserve();  //unsold tokens will be allocated back to Platrform growth reserve
    emit Finalized();
    isFinalized = true;
  }
  function Refundtokens(address _sender) internal {
        GrowthReserve = GrowthReserve.add(balances[_sender]);
        balances[_sender] = 0;
    }

  // if crowdsale is unsuccessful, investors can claim refunds here
  function claimRefund() public {
    require(isFinalized);
    require(!softcapReached());
    token.Refundtokens(msg.sender);
    vault.refund(msg.sender);
  }



  function softcapReached() public view returns (bool) {
    return weiRaised >= softcap;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > startTime + ICOperiod;
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
    bool withinPeriod = now >= startTime && now <= startTime + ICOperiod;
    bool validinput = msg.value >= minimumInvestment;
    return withinPeriod && validinput;
  }


}
