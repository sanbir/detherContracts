pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './dth/tokenfoundry/ERC223ReceivingContract.sol';
import './dth/tokenfoundry/ERC223Basic.sol';
import 'bytes/BytesLib.sol';
/// @title Contract that will store the Dth from user
contract DetherBank is ERC223ReceivingContract, Ownable, SafeMath  {
  using BytesLib for bytes;

  /*
   * Event
   */
  event receiveDth(address _from, uint amount);
  event receiveEth(address _from, uint amount);
  event sendDth(address _from, uint amount);
  event sendEth(address _from, uint amount);

  mapping(address => uint) public dthShopBalance;
  mapping(address => uint) public dthTellerBalance;
  mapping(address => uint) public ethShopBalance;
  mapping(address => uint) public ethTellerBalance;

  ERC223Basic public dth;
  bool public isInit = false;

  /**
   * INIT
   */
  function setDth (address _dth) {
    require(!isInit);
    dth = ERC223Basic(_dth);
    isInit = true;
  }

  /**
   * Core fonction
   */
  // withdraw DTH when teller delete
  function withdrawDthTeller(address _receiver) onlyOwner {
    require(dthTellerBalance[_receiver] > 0);
    uint tosend = dthTellerBalance[_receiver];
    dthTellerBalance[_receiver] = 0;
    require(dth.transfer(_receiver, tosend));
  }
  // withdraw DTH when shop delete
  function withdrawDthShop(address _receiver) onlyOwner  {
    require(dthShopBalance[_receiver] > 0);
    uint tosend = dthShopBalance[_receiver];
    dthShopBalance[_receiver] = 0;
    require(dth.transfer(_receiver, tosend));
  }
  // add DTH when shop register
  function addTokenShop(address _from, uint _value) public onlyOwner {
    dthShopBalance[_from] = SafeMath.add(dthShopBalance[_from], _value);
  }
  // add DTH when token register
  function addTokenTeller(address _from, uint _value) public onlyOwner{
    dthTellerBalance[_from] = SafeMath.add(dthTellerBalance[_from], _value);
  }
  // add ETH for escrow teller
  function addEthTeller(address _from, uint _value) public payable onlyOwner returns (bool) {
    ethTellerBalance[_from] = SafeMath.add(ethTellerBalance[_from] ,_value);
    return true;
  }
  // withdraw ETH for teller escrow
  function withdrawEth(address _from, address _to, uint _amount) public onlyOwner {
    require(ethTellerBalance[_from] >= _amount);
    ethTellerBalance[_from] = SafeMath.sub(ethTellerBalance[_from], _amount);
    _to.transfer(_amount);
  }
  // refund all ETH from teller contract
  function refundEth(address _from) public onlyOwner {
    uint toSend = ethTellerBalance[_from];
    if (toSend > 0) {
      ethTellerBalance[_from] = 0;
      _from.transfer(toSend);
    }
  }

  /**
   * GETTER
   */
  function getDthTeller(address _user) public view returns (uint) {
    return dthTellerBalance[_user];
  }
  function getDthShop(address _user) public view returns (uint) {
    return dthShopBalance[_user];
  }

  function getEthBalTeller(address _user) public view returns (uint) {
    return ethTellerBalance[_user];
  }
  /// @dev Standard ERC223 function that will handle incoming token transfers.
  // DO NOTHING but allow to receive token when addToken* function are called
  // by the dethercore contract
  function tokenFallback(address _from, uint _value, bytes _data) {

  }

}