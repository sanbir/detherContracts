pragma solidity ^0.5.8;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "../interfaces/IERC223ReceivingContract.sol";
import "../interfaces/IDetherToken.sol";


contract TaxCollector is IERC223ReceivingContract, Ownable {

    uint public taxBalance;
    // Address where collected taxes are sent to
    address public taxRecipient;
    bool public unchangeable;
    IDetherToken public dth;
    // Daily tax rate (there are no floats in solidity)

    constructor(address _dth, address _taxRecipient) public {
        dth = IDetherToken(_dth);
        taxRecipient = _taxRecipient;
    }

    function unchangeableRecipient()
      onlyOwner
      external
    {
        unchangeable = true;
    }

    function changeRecipient(address _newOwner)
      external 
      onlyOwner
    {
        require(!unchangeable, 'Impossible to change the recipient');
        taxRecipient = _newOwner;
    }

    function collect()
      public
    {
        // send to taxRecipient;
        uint balance = dth.balanceOf(address(this));
        dth.transfer(taxRecipient, balance);
    }

    function tokenFallback(address _from, uint _value, bytes memory _data) 
      public
    {
        // require(msg.sender == address(dth), "can only be called by dth contract");
        // taxBalance += _value;
    }
}